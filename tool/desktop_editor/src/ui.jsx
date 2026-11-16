import React, { useEffect } from 'react';

export function Dialog({ title, children, actions, onClose }) {
  useEffect(() => {
    const k = (e) => e.key === 'Escape' && onClose && onClose();
    window.addEventListener('keydown', k);
    return () => window.removeEventListener('keydown', k);
  }, [onClose]);
  return (
    <div className="scrim" role="presentation">
      <div className="dialog" role="dialog" aria-modal="true" aria-label={title}>
        <h2>{title}</h2>
        <div className="dialog-body">{children}</div>
        <div className="dialog-actions">{actions}</div>
      </div>
    </div>
  );
}

export function Icon({ d }) {
  return (
    <svg viewBox="0 0 20 20" width="16" height="16" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d={d} />
    </svg>
  );
}
export const ICONS = {
  up: 'M10 16V4M5 9l5-5 5 5',
  down: 'M10 4v12M5 11l5 5 5-5',
  trash: 'M4 6h12M8 6V4h4v2M6 6l1 10h6l1-10',
  undo: 'M7 5 3 9l4 4M3 9h9a5 5 0 0 1 0 10h-2',
  redo: 'M13 5l4 4-4 4M17 9H8a5 5 0 0 0 0 10h2',
  plus: 'M10 4v12M4 10h12',
  left: 'M16 10H4M9 5l-5 5 5 5',
  right: 'M4 10h12M11 5l5 5-5 5',
  upload: 'M10 14V4M5 9l5-5 5 5M4 17h12',
  swap: 'M4 7h12l-3-3M16 13H4l3 3',
};
