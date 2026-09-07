import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })

function readDefaultKey(jsonName: string, legacyName: string): string {
  const encoded = Deno.env.get(jsonName)
  if (encoded) {
    try {
      const keys = JSON.parse(encoded) as Record<string, string>
      if (keys.default) return keys.default
    } catch {
      console.error(`Invalid ${jsonName} environment variable`)
    }
  }
  return Deno.env.get(legacyName) ?? ''
}

async function deleteUserFiles(
  admin: ReturnType<typeof createClient>,
  userId: string,
) {
  const prefix = `users/${userId}/notes`
  const listAll = async (path: string) => {
    const items = []
    for (let offset = 0; ; offset += 1000) {
      const { data, error } = await admin.storage
        .from('note-files')
        .list(path, { limit: 1000, offset })
      if (error) throw error
      items.push(...(data ?? []))
      if (!data || data.length < 1000) return items
    }
  }

  const noteFolders = await listAll(prefix)

  const paths: string[] = []
  for (const folder of noteFolders) {
    const folderPath = `${prefix}/${folder.name}`
    if (folder.id) {
      paths.push(folderPath)
      continue
    }
    const files = await listAll(folderPath)
    for (const file of files) {
      if (file.id) paths.push(`${folderPath}/${file.name}`)
    }
  }

  if (paths.length > 0) {
    const { error: removeError } = await admin.storage
      .from('note-files')
      .remove(paths)
    if (removeError) throw removeError
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  const authorization = request.headers.get('Authorization')
  if (!authorization?.startsWith('Bearer ')) {
    return json({ error: 'Missing authorization' }, 401)
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const publishableKey = readDefaultKey(
      'SUPABASE_PUBLISHABLE_KEYS',
      'SUPABASE_ANON_KEY',
    )
    const secretKey = readDefaultKey(
      'SUPABASE_SECRET_KEYS',
      'SUPABASE_SERVICE_ROLE_KEY',
    )

    const userClient = createClient(supabaseUrl, publishableKey, {
      global: { headers: { Authorization: authorization } },
    })
    const token = authorization.replace('Bearer ', '')
    const { data: userData, error: userError } = await userClient.auth.getUser(token)
    if (userError || !userData.user) return json({ error: 'Unauthorized' }, 401)
    if (!secretKey) throw new Error('Missing server-side Supabase secret')

    const admin = createClient(supabaseUrl, secretKey)
    await deleteUserFiles(admin, userData.user.id)

    const { error: dataError } = await admin
      .from('studiary_data')
      .delete()
      .eq('user_id', userData.user.id)
    if (dataError) throw dataError

    const { error: deleteError } = await admin.auth.admin.deleteUser(userData.user.id)
    if (deleteError) throw deleteError

    return json({ deleted: true })
  } catch (error) {
    console.error(error)
    return json({ error: error instanceof Error ? error.message : 'Account deletion failed' }, 500)
  }
})
