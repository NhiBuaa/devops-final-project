import axios from 'axios';
import type { Member } from './types';

const rawApiUrl = import.meta.env.VITE_API_URL?.trim();

// Use same-origin API by default so each environment talks to its own ingress.
// If a mismatched absolute URL is injected at build time, fall back to /api.
const API_URL =
    rawApiUrl &&
    typeof window !== 'undefined' &&
    /^https?:\/\//.test(rawApiUrl) &&
    new URL(rawApiUrl).hostname !== window.location.hostname
        ? '/api'
        : rawApiUrl || '/api';

export const api = axios.create({
    baseURL: API_URL,
});

export const getMembers = () => api.get<Member[]>('/members');
export const createMember = (member: Omit<Member, 'id'>) => api.post<Member>('/members', member);
export const updateMember = (id: number, member: Omit<Member, 'id'>) => api.put<Member>(`/members/${id}`, member);
export const deleteMember = (id: number) => api.delete(`/members/${id}`);
