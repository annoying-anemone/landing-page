import { describe, expect, it, vi } from 'vitest';

const configMock = vi.hoisted(() => ({
  SITE: {
    base: '/',
    site: 'https://example.com',
    trailingSlash: false,
  },
  APP_BLOG: {
    list: { pathname: 'blog' },
    category: { pathname: 'category' },
    tag: { pathname: 'topics' },
    post: { permalink: 'blog/%slug%' },
  },
  I18N: {
    language: 'en-US',
  },
}));

vi.mock('astrowind:config', () => configMock);

import { applyGetPermalinks, getAsset, getCanonical, getPermalink, trimSlash } from '../permalinks';
import { trim } from '../utils';

describe('string helpers', () => {
  it('trims characters and slashes predictably', () => {
    expect(trimSlash('///field-notes///')).toBe('field-notes');
    expect(trim('---mission-complete---', '-')).toBe('mission-complete');
  });
});

describe('permalink builders', () => {
  it('returns canonical URLs that honor trailing slash settings', () => {
    expect(getCanonical('about')).toBe('https://example.com/about');
    expect(getCanonical('/')).toBe('https://example.com');
  });

  it('creates internal links for pages, categories, and tags', () => {
    expect(getPermalink('pricing')).toBe('/pricing');
    expect(getPermalink('research', 'category')).toBe('/category/research');
    expect(getPermalink('field-kit', 'tag')).toBe('/topics/field-kit');
  });

  it('returns untouched URLs for external or already qualified links', () => {
    const external = 'https://conservation.example/blog';
    expect(getPermalink(external)).toBe(external);
    expect(getPermalink('#features')).toBe('#features');
  });

  it('derives asset paths relative to the site base', () => {
    expect(getAsset('images/logo.svg')).toBe('/images/logo.svg');
    expect(getAsset('/downloads/guide.pdf')).toBe('/downloads/guide.pdf');
  });
});

describe('menu normalization', () => {
  it('recursively normalizes href entries using applyGetPermalinks', () => {
    const menu = [
      { label: 'Home', href: { type: 'home', url: '' } },
      { label: 'Docs', href: '/docs/' },
      { label: 'Blog', href: { type: 'blog', url: '' } },
      {
        label: 'Deep link',
        child: {
          href: { type: 'tag', url: 'biodiversity' },
        },
      },
    ];

    const normalized = applyGetPermalinks(menu) as Array<Record<string, unknown>>;
    expect(normalized[0].href).toBe('/');
    expect(normalized[1].href).toBe('/docs');
    expect(normalized[2].href).toBe('/blog');
    expect((normalized[3].child as Record<string, string>).href).toBe('/topics/biodiversity');
  });
});
