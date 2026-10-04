# Facebook feed mock

A self-contained, believable scrollable Facebook feed — plain HTML/CSS/JS, no build
step and no dependencies. Used to demo/scroll past a fake-news post with an image.

## Run

Just open `index.html` in a browser. Or serve it locally:

```powershell
# optional, any static server works
npx serve .
```

## What's in it

- Facebook-style top bar, left shortcuts, stories row, composer, and a contacts column.
- Infinite scroll (more posts load as you reach the bottom).
- Like/comment/share interactions (mock); sponsored post; link previews.
- **One featured fake-news post with an image** — the pigeon-mayor story.

## The image (action needed)

`assets/pigeon-mayor.svg` is a **hand-made placeholder** (I have no image-generation
tool). It is intentionally a bit "off" (three eyes, an extra hand, garbled text) so it
reads as an obviously-AI image.

To use a real AI-generated image:

1. Drop your image into `assets/` (e.g. `assets/pigeon-mayor.jpg`).
2. Update the `FEATURED_IMAGE` constant at the top of `app.js` to the new path.

Any 16:9-ish image looks best in the post.
