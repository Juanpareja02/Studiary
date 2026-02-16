
'use client';

import { useState, useRef } from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogTrigger,
  DialogClose,
} from '@/components/ui/dialog';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Notebook, PlusCircle, Archive, Trash2, Edit, Inbox, ArchiveRestore, FileText, FileImage, FileUp, Eye } from 'lucide-react';
import type { Subject, Note, NoteType } from '@/lib/types';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

interface NotesViewProps {
  subjects: Subject[];
  notes: Note[];
  setNotes: (notes: Note[]) => void;
}

const NotePreviewDialog = ({ note, isOpen, setIsOpen }: { note: Note | undefined, isOpen: boolean, setIsOpen: (isOpen: boolean) => void }) => {
    if (!note) return null;

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogContent className="max-w-4xl h-[90vh]">
                <DialogHeader>
                    <DialogTitle>{note.title}</DialogTitle>
                </DialogHeader>
                <div className="h-full w-full py-4 flex items-center justify-center">
                    {note.type === 'image' && note.fileDataUri && (
                        <img src={note.fileDataUri} alt={note.title} className="max-h-full max-w-full object-contain" />
                    )}
                    {note.type === 'pdf' && note.fileDataUri && (
                        <iframe src={note.fileDataUri} className="w-full h-full" title={note.title} />
                    )}
                </div>
            </DialogContent>
        </Dialog>
    )
}

const NoteEditorDialog = ({
  isOpen,
  setIsOpen,
  onSave,
  noteToEdit,
  subjects,
  subjectId: initialSubjectId,
}: {
  isOpen: boolean;
  setIsOpen: (isOpen: boolean) => void;
  onSave: (note: Omit<Note, 'id' | 'createdAt' | 'updatedAt' | 'archived'> | Note) => void;
  noteToEdit?: Note;
  subjects: Subject[];
  subjectId?: string;
}) => {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [subjectId, setSubjectId] = useState('');

  useState(() => {
    if (noteToEdit) {
      setTitle(noteToEdit.title);
      setContent(noteToEdit.content || '');
      setSubjectId(noteToEdit.subjectId);
    } else {
      setTitle('');
      setContent('');
      setSubjectId(initialSubjectId || '');
    }
  });

  const handleSave = () => {
    if (!title || !subjectId) return; // Basic validation
    const noteData = {
        ...noteToEdit,
        id: noteToEdit?.id || new Date().toISOString(),
        title,
        content,
        subjectId,
        type: 'text' as NoteType,
        fileDataUri: undefined,
        fileName: undefined,
        archived: noteToEdit?.archived || false,
        createdAt: noteToEdit?.createdAt || new Date(),
        updatedAt: new Date(),
    };
    onSave(noteData);
    setIsOpen(false);
  };
  
  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent className="sm:max-w-[625px]">
        <DialogHeader>
          <DialogTitle>{noteToEdit ? 'Editar Apunte' : 'Nuevo Apunte de Texto'}</DialogTitle>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <div className="grid gap-2">
            <Label htmlFor="title">Título</Label>
            <Input id="title" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Título del apunte" />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="subject">Asignatura</Label>
            <select
                id="subject"
                value={subjectId}
                onChange={(e) => setSubjectId(e.target.value)}
                className="flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            >
                <option value="" disabled>Selecciona una asignatura</option>
                {subjects.map(s => (
                    <option key={s.id} value={s.id}>{s.name}</option>
                ))}
            </select>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="content">Contenido</Label>
            <Textarea id="content" value={content} onChange={(e) => setContent(e.target.value)} placeholder="Escribe tus apuntes aquí..." className="min-h-[250px]" />
          </div>
        </div>
        <DialogFooter>
          <DialogClose asChild>
            <Button type="button" variant="secondary">Cancelar</Button>
          </DialogClose>
          <Button onClick={handleSave} disabled={!title || !subjectId}>Guardar</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};


const FileUploaderDialog = ({
  isOpen,
  setIsOpen,
  onSave,
  subjects,
  subjectId: initialSubjectId,
  noteType,
}: {
  isOpen: boolean;
  setIsOpen: (isOpen: boolean) => void;
  onSave: (note: Omit<Note, 'id' | 'createdAt' | 'updatedAt' | 'archived' | 'content'>) => void;
  subjects: Subject[];
  subjectId?: string;
  noteType: 'pdf' | 'image';
}) => {
    const [file, setFile] = useState<File | null>(null);
    const [title, setTitle] = useState('');
    const [subjectId, setSubjectId] = useState(initialSubjectId || '');
    const fileInputRef = useRef<HTMLInputElement>(null);

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            const currentFile = e.target.files[0];
            // Limit file size to 5MB to avoid quota issues on most browsers
            if (currentFile.size > 5 * 1024 * 1024) {
                alert("El archivo es demasiado grande. El límite es de 5MB.");
                setFile(null);
                return;
            }
            setFile(currentFile);
            if(!title) {
                setTitle(currentFile.name);
            }
        }
    };
    
    const handleSave = () => {
        if(!file || !title || !subjectId) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            const fileDataUri = e.target?.result as string;
            const noteData = {
                id: new Date().toISOString(),
                title,
                subjectId,
                type: noteType,
                fileDataUri,
                fileName: file.name,
                archived: false,
                createdAt: new Date(),
                updatedAt: new Date(),
            }
            onSave(noteData);
            setIsOpen(false);
            setFile(null);
            setTitle('');
        };
        reader.readAsDataURL(file);
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogContent>
                <DialogHeader>
                    <DialogTitle>Subir {noteType === 'pdf' ? 'PDF' : 'Imagen'}</DialogTitle>
                </DialogHeader>
                <div className="space-y-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="file-title">Título</Label>
                        <Input id="file-title" value={title} onChange={e => setTitle(e.target.value)} placeholder="Nombre del archivo" />
                    </div>
                     <div className="grid gap-2">
                        <Label htmlFor="subject-file">Asignatura</Label>
                        <select
                            id="subject-file"
                            value={subjectId}
                            onChange={(e) => setSubjectId(e.target.value)}
                            className="flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            <option value="" disabled>Selecciona una asignatura</option>
                            {subjects.map(s => (
                                <option key={s.id} value={s.id}>{s.name}</option>
                            ))}
                        </select>
                    </div>
                    <div className="space-y-2">
                        <Label>Archivo (Máx 5MB)</Label>
                        <div 
                          className="flex items-center justify-center w-full p-6 border-2 border-dashed rounded-md cursor-pointer"
                          onClick={() => fileInputRef.current?.click()}
                        >
                            <div className="text-center">
                                <FileUp className="mx-auto h-10 w-10 text-muted-foreground" />
                                {file ? (
                                    <p className="mt-2 text-sm font-medium">{file.name}</p>
                                ) : (
                                    <p className="mt-2 text-sm text-muted-foreground">Haz clic para seleccionar un archivo</p>
                                )}
                            </div>
                        </div>
                        <Input 
                            ref={fileInputRef}
                            type="file" 
                            className="hidden"
                            accept={noteType === 'pdf' ? '.pdf' : 'image/*'}
                            onChange={handleFileChange}
                        />
                    </div>
                </div>
                <DialogFooter>
                     <DialogClose asChild>
                        <Button type="button" variant="secondary">Cancelar</Button>
                    </DialogClose>
                    <Button onClick={handleSave} disabled={!file || !title || !subjectId}>Guardar</Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    )
}

const NoteTypeSelectionDialog = ({ onSelect, children }: { onSelect: (type: NoteType) => void, children: React.ReactNode }) => {
    const [isOpen, setIsOpen] = useState(false);

    const handleSelect = (type: NoteType) => {
        onSelect(type);
        setIsOpen(false);
    }
    
    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild>{children}</DialogTrigger>
            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle>Crear nuevo apunte</DialogTitle>
                </DialogHeader>
                <div className="flex justify-around p-8 gap-4">
                    <Button variant="outline" className="flex flex-col h-24 w-24" onClick={() => handleSelect('text')}>
                        <FileText className="h-8 w-8 mb-2" />
                        Texto
                    </Button>
                     <Button variant="outline" className="flex flex-col h-24 w-24" onClick={() => handleSelect('pdf')}>
                        <FileText className="h-8 w-8 mb-2" />
                        PDF
                    </Button>
                     <Button variant="outline" className="flex flex-col h-24 w-24" onClick={() => handleSelect('image')}>
                        <FileImage className="h-8 w-8 mb-2" />
                        Imagen
                    </Button>
                </div>
            </DialogContent>
        </Dialog>
    )
}


export default function NotesView({ subjects, notes, setNotes }: NotesViewProps) {
  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const [isFileUploaderOpen, setIsFileUploaderOpen] = useState(false);
  const [editingNote, setEditingNote] = useState<Note | undefined>(undefined);
  const [initialSubjectId, setInitialSubjectId] = useState<string | undefined>(undefined);
  const [noteTypeToCreate, setNoteTypeToCreate] = useState<NoteType | undefined>(undefined);
  const [previewNote, setPreviewNote] = useState<Note | undefined>(undefined);
  const [isPreviewOpen, setIsPreviewOpen] = useState(false);

  const handleSaveNote = (noteData: Note) => {
    const existing = notes.find(n => n.id === noteData.id);
    if(existing) {
        const updatedNotes = notes.map(n => n.id === noteData.id ? {...noteData, fileDataUri: n.fileDataUri || noteData.fileDataUri } : n);
        setNotes(updatedNotes);
    } else {
        setNotes([...notes, noteData]);
    }
  };

  const handleArchiveNote = (noteId: string, archive = true) => {
    setNotes(notes.map(n => n.id === noteId ? { ...n, archived: archive } : n));
  };
  
  const handleDeleteNote = (noteId: string) => {
    setNotes(notes.filter(n => n.id !== noteId));
  };

  const openEditorForNew = (subjectId: string, type: NoteType) => {
    setInitialSubjectId(subjectId);
    setEditingNote(undefined);
    if(type === 'text') {
      setIsEditorOpen(true);
    } else {
      setNoteTypeToCreate(type);
      setIsFileUploaderOpen(true);
    }
  }
  
  const openEditorForEdit = (note: Note) => {
    if(note.type === 'text') {
      setEditingNote(note);
      setInitialSubjectId(undefined);
      setIsEditorOpen(true);
    }
    // Editing for file-based notes can be added here
  }
  
  const openPreview = (note: Note) => {
    setPreviewNote(note);
    setIsPreviewOpen(true);
  }

  const activeNotes = notes.filter(n => !n.archived);
  const archivedNotes = notes.filter(n => n.archived);

  return (
    <>
    <Card className="shadow-lg">
      <CardHeader>
        <CardTitle className="flex items-center gap-3 font-headline text-xl capitalize">
          <Notebook className="h-6 w-6 text-primary" />
          Mis Apuntes
        </CardTitle>
        <CardDescription>Crea, edita y organiza tus apuntes por asignatura. Guarda apuntes de texto, PDF o imágenes.</CardDescription>
      </CardHeader>
      <CardContent>
        <Accordion type="multiple" defaultValue={subjects.map(s => s.id)} className="w-full space-y-4">
          {subjects.map(subject => {
            const subjectNotes = activeNotes.filter(n => n.subjectId === subject.id);
            return (
              <AccordionItem value={subject.id} key={subject.id} className="border rounded-lg overflow-hidden">
                <AccordionTrigger className="p-4 hover:no-underline" style={{backgroundColor: `${subject.color}20`}}>
                  <div className="flex items-center gap-3">
                    <div className="h-2 w-2 rounded-full" style={{backgroundColor: subject.color}} />
                    <span className="font-semibold" style={{color: subject.color}}>{subject.name}</span>
                  </div>
                </AccordionTrigger>
                <AccordionContent className="p-4">
                  {subjectNotes.length > 0 ? (
                    <div className="space-y-2">
                      {subjectNotes.map(note => (
                        <div key={note.id} className="flex justify-between items-center p-3 rounded-md border">
                          <div className="flex items-center gap-3">
                            {note.type === 'pdf' ? <FileText className="h-5 w-5 text-muted-foreground" /> :
                             note.type === 'image' ? <FileImage className="h-5 w-5 text-muted-foreground" /> :
                             <FileText className="h-5 w-5 text-muted-foreground" />}
                            <div>
                                <p className="font-medium">{note.title}</p>
                                <p className="text-xs text-muted-foreground">
                                  Actualizado: {format(note.updatedAt, "P p", { locale: es })}
                                </p>
                            </div>
                          </div>
                          <div className="flex items-center gap-1">
                             {note.type === 'text' && <Button variant="ghost" size="icon" onClick={() => openEditorForEdit(note)}><Edit className="h-4 w-4" /></Button>}
                             {(note.type === 'pdf' || note.type === 'image') && note.fileDataUri &&
                                <Button variant="ghost" size="icon" title="Visualizar" onClick={() => openPreview(note)}>
                                  <Eye className="h-4 w-4" />
                                </Button>
                              }
                             <Button variant="ghost" size="icon" onClick={() => handleArchiveNote(note.id)} title="Archivar"><Archive className="h-4 w-4" /></Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-muted-foreground text-center py-4">No tienes apuntes para esta asignatura.</p>
                  )}
                  <NoteTypeSelectionDialog onSelect={(type) => openEditorForNew(subject.id, type)}>
                    <Button variant="outline" className="w-full mt-4">
                        <PlusCircle className="mr-2 h-4 w-4" />
                        Añadir Apunte
                    </Button>
                  </NoteTypeSelectionDialog>
                </AccordionContent>
              </AccordionItem>
            )
          })}

          {archivedNotes.length > 0 && (
             <AccordionItem value="archived" className="border rounded-lg overflow-hidden">
                <AccordionTrigger className="p-4 hover:no-underline bg-muted/50">
                  <div className="flex items-center gap-3">
                    <Archive className="h-5 w-5 text-muted-foreground" />
                    <span className="font-semibold">Apuntes Archivados</span>
                  </div>
                </AccordionTrigger>
                <AccordionContent className="p-4">
                     <div className="space-y-2">
                      {archivedNotes.map(note => (
                        <div key={note.id} className="flex justify-between items-center p-3 rounded-md border bg-muted/20">
                           <div className="flex items-center gap-3">
                            {note.type === 'pdf' ? <FileText className="h-5 w-5 text-muted-foreground" /> :
                             note.type === 'image' ? <FileImage className="h-5 w-5 text-muted-foreground" /> :
                             <FileText className="h-5 w-5 text-muted-foreground" />}
                             <div>
                                <p className="font-medium text-muted-foreground">{note.title}</p>
                                <p className="text-xs text-muted-foreground">
                                  {subjects.find(s => s.id === note.subjectId)?.name}
                                </p>
                              </div>
                           </div>
                          <div className="flex items-center gap-1">
                             <Button variant="ghost" size="icon" onClick={() => handleArchiveNote(note.id, false)} title="Desarchivar"><ArchiveRestore className="h-4 w-4" /></Button>
                             <AlertDialog>
                                <AlertDialogTrigger asChild>
                                    <Button variant="ghost" size="icon" className="text-destructive hover:text-destructive" title="Eliminar"><Trash2 className="h-4 w-4" /></Button>
                                </AlertDialogTrigger>
                                <AlertDialogContent>
                                <AlertDialogHeader>
                                    <AlertDialogTitle>¿Eliminar permanentemente?</AlertDialogTitle>
                                    <AlertDialogDescription>
                                    Esta acción no se puede deshacer. El apunte se eliminará para siempre.
                                    </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                    <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                    <AlertDialogAction onClick={() => handleDeleteNote(note.id)}>Eliminar</AlertDialogAction>
                                </AlertDialogFooter>
                                </AlertDialogContent>
                            </AlertDialog>
                          </div>
                        </div>
                      ))}
                    </div>
                </AccordionContent>
              </AccordionItem>
          )}

        </Accordion>
      </CardContent>
    </Card>
    <NotePreviewDialog note={previewNote} isOpen={isPreviewOpen} setIsOpen={setIsPreviewOpen} />
    { isEditorOpen && <NoteEditorDialog 
        isOpen={isEditorOpen}
        setIsOpen={setIsEditorOpen}
        onSave={handleSaveNote as any}
        noteToEdit={editingNote}
        subjects={subjects}
        subjectId={initialSubjectId}
    />}
    { isFileUploaderOpen && noteTypeToCreate && (noteTypeToCreate === 'pdf' || noteTypeToCreate === 'image') && <FileUploaderDialog
        isOpen={isFileUploaderOpen}
        setIsOpen={setIsFileUploaderOpen}
        onSave={handleSaveNote as any}
        subjects={subjects}
        subjectId={initialSubjectId}
        noteType={noteTypeToCreate}
    />}
    </>
  );
}

    
