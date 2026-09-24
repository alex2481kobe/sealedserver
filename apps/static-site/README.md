# Static Site

Plain files served by nginx: HTML, CSS, JavaScript, images, `robots.txt`,
`sitemap.xml`, or the output of a frontend build.

```text
/var/www/<app>/public/
  index.html
  404.html
  assets/        cached for a year
```

Files under `assets/` are cached for a year by browsers and Cloudflare. A
changed asset needs a new URL, either a hashed file name from a build tool or a
query string such as `styles.css?v=20260101a`. Everything else is cached for
five minutes.

To set up and deploy a static site, see
[Apps](../../documentation/apps.md#static-site).
