import { SITE } from 'astrowind:config';
import { getPermalink, getBlogPermalink, getAsset } from './utils/permalinks';

export const headerData = {
  links: [
    {
      text: 'Home',
      href: getPermalink('/'),
    },
    {
      text: 'Features',
      href: getPermalink('/#features'),
    },
    {
      text: 'Services',
      href: getPermalink('/services'),
    },
    {
      text: 'Pricing',
      href: getPermalink('/pricing'),
    },
    {
      text: 'About us',
      href: getPermalink('/about'),
    },
    {
      text: 'Contact',
      href: getPermalink('/contact'),
    },
    {
      text: 'Blog',
      href: getBlogPermalink(),
    },
  ],
};

export const footerData = {
  links: [
    {
      title: 'Product',
      links: [
        { text: 'Features', href: getPermalink('/#features') },
        { text: 'Services', href: getPermalink('/services') },
        { text: 'Pricing', href: getPermalink('/pricing') },
        { text: 'About us', href: getPermalink('/about') },
      ],
    },
    {
      title: 'Support',
      links: [
        { text: 'Developer API', href: `${SITE.products.sense}/api` },
        { text: 'Docs', href: `${SITE.products.sense}/docs` },
        { text: 'Status', href: SITE.products.status },
      ],
    },
    {
      title: 'Company',
      links: [
        { text: 'About', href: getPermalink('/about') },
        { text: 'Blog', href: getBlogPermalink() },
        { text: 'Careers', href: getPermalink('/careers') },
        { text: 'Social Impact', href: getPermalink('/social-impact') },
      ],
    },
  ],
  secondaryLinks: [
    { text: 'Terms', href: getPermalink('/terms') },
    { text: 'Privacy Policy', href: getPermalink('/privacy') },
  ],
  socialLinks: [
    { ariaLabel: 'X', icon: 'tabler:brand-x', href: `https://${SITE.social.x}` },
    { ariaLabel: 'RSS', icon: 'tabler:rss', href: getAsset('/rss.xml') },
    { ariaLabel: 'Github', icon: 'tabler:brand-github', href: `https://${SITE.social.github}` },
  ],
  footNote: `
    Made by <a class="text-blue-600 underline dark:text-muted" href="${getPermalink('/about')}">${SITE.name}</a> · All rights reserved.
  `,
};
