// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
  site: 'https://kaitos.dev',
  integrations: [
    starlight({
      title: 'Kaitos Toolchain',
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/kernelle-soft/kaitos-toolchain'
        }
      ],
      sidebar: [
        {
          label: 'Guides',
          items: [
            // Each item here is one entry in the navigation menu.
            { label: 'Example Guide', slug: 'guides/example' },
          ],
        },
        {
          label: 'Reference',
          autogenerate: { directory: 'reference' },
        },
      ],
    })
  ],
});