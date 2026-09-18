import { StrictMode, Suspense } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App.js';

const racine = document.getElementById('racine');
if (!racine) {
  throw new Error('Element #racine introuvable : index.html a-t-il ete modifie ?');
}

createRoot(racine).render(
  <StrictMode>
    <Suspense fallback={null}>
      <App />
    </Suspense>
  </StrictMode>,
);
