// Centralized backend URL configuration for the frontend.
// Set VITE_BACKEND_URL in your frontend environment for deployment builds.
export const BACKEND_URL: string = (import.meta as any).env?.VITE_BACKEND_URL || 'http://localhost:8787';
