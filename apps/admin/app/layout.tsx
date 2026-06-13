import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'SafeRoute Admin',
  description: 'School bus safety and tracking admin panel',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

