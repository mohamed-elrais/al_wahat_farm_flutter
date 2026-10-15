// Cloudflare Pages Function for /api/photos/* (see server/photos.mjs).
import { handlePhotoRequest } from '../../../server/photos.mjs';

export const onRequest = (context) =>
  handlePhotoRequest(context.request, context.env);
