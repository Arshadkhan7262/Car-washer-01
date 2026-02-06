import DOMPurify from 'dompurify';
import { JSDOM } from 'jsdom';

// Create a JSDOM window for DOMPurify to work in Node.js
const window = new JSDOM('').window;
const purify = DOMPurify(window);

/**
 * Sanitize HTML content to prevent XSS attacks
 * Allows safe HTML tags and attributes for rich text content
 */
export const sanitizeHTML = (html) => {
  if (!html || typeof html !== 'string') {
    return '';
  }

  return purify.sanitize(html, {
    ALLOWED_TAGS: [
      'p', 'br', 'strong', 'em', 'u', 's', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'ul', 'ol', 'li', 'a', 'blockquote', 'div', 'span', 'img'
    ],
    ALLOWED_ATTR: [
      'href', 'title', 'alt', 'src', 'class', 'style', 'width', 'height'
    ],
    // Allow HTTPS/HTTP image URLs (important for mobile apps)
    ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|sms|cid|xmpp|data):|[^a-z]|[a-z+.\-]+(?:[^a-z+.\-:]|$))/i,
    // Keep image content even if URL validation fails (will be filtered by ALLOWED_URI_REGEXP)
    KEEP_CONTENT: true,
    RETURN_DOM: false,
    RETURN_DOM_FRAGMENT: false,
    RETURN_TRUSTED_TYPE: false,
    // Ensure images use safe protocols
    ADD_ATTR: ['target'], // Allow target="_blank" for links
  });
};
