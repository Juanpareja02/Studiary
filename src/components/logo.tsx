
import * as React from 'react';
import Image from 'next/image';
import { cn } from '@/lib/utils';

export const Logo = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
    <div className={cn("relative", className)} {...props}>
        <Image
            src="/logos/LogoStudiary.png"
            alt="Studiary Logo"
            fill
            style={{ objectFit: 'contain' }}
        />
    </div>
);
