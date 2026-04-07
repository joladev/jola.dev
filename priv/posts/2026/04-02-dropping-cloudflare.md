%{
  title: "Dropping Cloudflare for bunny.net",
  author: "Johanna Larsson",
  tags: ~w(elixir phoenix blog bunnynet),
  description: "Dropping Cloudflare and migrating to bunny.net, starting out with my blog."
}
---

TL;DR my motivation and experience for moving my blog from Cloudflare to [bunny.net](https://bunny.net?ref=f0l8865b7g)

I’ve been a long time Cloudflare user. They offer a solid service that is free for the vast majority of their users, that’s very generous. Their infrastructure is massive and their feature set is undeniably incredible. 

One of my biggest concerns though is around how easily I could become heavily dependent on this one single company that then can decide to cut me off and disable all of my websites, for any arbitrary reason. It’s a single point of failure for the internet. Every Cloudflare outage ends up in the news. And I can’t help but feel that the idea of centralizing the internet into a single US corporation feels off. Not to mention the various scandals that have surrounded them. So I was open to alternatives.

## Bunny.net

[Bunny.net](https://bunny.net?ref=f0l8865b7g) is a Slovenian (EU) company that is building up a lot of momentum. Their CDN-related services rival Cloudflare already, and although their PoP network is smaller than Cloudflare’s, they score highly on performance and speed across the globe. It’s a genuinely competitive alternative to Cloudflare.

It has the additional benefit of being a European company, and I like the idea of growing and supporting the European tech scene.

## What I was moving away from

I’ve been using various different services, but focusing on this blog, the first thing was Cloudflare as the registrar for the domain name. I did some research on alternative registrars, but I just didn’t find any good European options. The closest I found was INWX, but their lack of free WHOIS Privacy made them a non-option. I ended up with Porkbun. They run on Cloudflare infrastructure, but they have better support. So the remaining thing Cloudflare was doing for me was the “Orange Cloud”: automatic caching, origin hiding, and optional protection features.

So that’s what we’re moving over! I’m gonna walk you through how to set up the bunny.net CDN for your website, with some sensible defaults.

## Step by step

Setting up your [bunny.net](https://bunny.net?ref=f0l8865b7g) account is quick and you get $20 worth of free credits to play around with, those are valid for 14 days. You don’t need to give them a credit card up front to try things out, but if you do, you get another $30 worth of credits. You do need to confirm your email though before you can start setting things up. Once you’re out of the trial, you pay per use, which for most cases is cents a month. However, note that bunny.net require a minimum payment of $1 per month.

I guess a cheap price to pay to *stop being the product* and start becoming the customer.

### Creating your pull zone

The pull zone is the main mechanism for enabling the CDN for your website. You’ll find them under CDN in the left navigation bar. Here’s how to set one up:

1. Fill in the pull zone name. Just make it something meaningful to you, for example the website name.
2. For origin type, select Origin URL.
3. Fill in your Origin URL. This would be the address for directly accessing your server. In my case, it’s the public IP of my server. 
4. If you’re running multiple apps on your server, for example using Dokploy, coolify, or self-hosted PaaSs like that, you’ll want to pass the Host header as well. Here you put in the domain of your app. In my case, that’s jola.dev.
5. For tier, select Standard.
6. Finally you can select your pricing zones. Note that some zones are more expensive, so you can choose to disable them. This just means that people in those areas will get redirected to the closest zone you do have enabled.

And you’re done with the first part!

### Configuring your pull zone

Now that you’ve set up the pull zone, it’s time to hook it up to your website and domain. Go to the pull zone you created. You’ll see a “hostnames” screen. Time to connect things.

1. Under “Add a custom hostname” fill in your website domain name.
2. You’ll get a modal with some instructions. You need to follow them to set up the DNS name to point your website to go through the CDN.
3. Go to where you manage domain name and add a CNAME record to point your domain to the given CNAME value in the modal, something like website.b-cdn.net.
4. Once you’ve done that, wait a few minutes to let it propagate, and then click “Verify & Activate SSL”. 
5. If it says success, you’re done. Your website is now running through the bunny.net CDN, similar to the Cloudflare orange cloud.

### Configuring caching

This is the part where bunny.net will really shine through!

If your website is set up to return the appropriate cache headers for each resource, things will just work. Bunny defaults to respecting the cache control headers when pointing a pull zone at an origin site. To verify, go to Caching → General and check that “Respect origin Cache-Control” is set under “Cache expiration time”. Note that if you set `no-cache`, bunny will use that and will not cache at the edge.

Alternatively, if you don’t have cache headers set up, and you don’t want to control that yourself, you can instead enable Smart Cache. This will default to caching typically cached resources like images, CSS, JS files etc, while avoiding caching things like HTML pages. This will work for most cases!

But I wanted to go *faster*. If you’ve read my post about building this website, here’s how I’ve set up my cache headers: I added a new pipeline in the router called `public` and added an extra middleware to it. I technically have everything using this pipeline, but leaving the standard `browser` pipeline that comes out of the box with Phoenix keeps my options open to add authenticated (uncached) pages in the future. 

```elixir
  pipeline :public do
    plug :accepts, ["html"]
    plug :put_root_layout, html: {JolaDevWeb.Layouts, :root}
    plug :put_secure_browser_headers, @secure_headers
    plug :put_cdn_cache_header
  end
  
  defp put_cdn_cache_header(conn, _opts) do
    put_resp_header(conn, "cache-control", "public, s-maxage=86400, max-age=0")
  end
```

You can see the whole router here https://github.com/joladev/jola.dev/blob/main/lib/jola_dev_web/router.ex.

This setup means I even cache the HTML pages, which makes this ridiculously fast. Here’s the landing page response time from various locations, using the [Larm response time checker tool](https://larm.dev/tools/response-time/r/89374810-dbb3-4227-87d1-9a947be29e49):

<img src="/images/joladev-larm-response-time.png" style="margin-bottom:16px" />

Because I’m caching the HTML pages, if I publish a new post I do need to purge the pull zone to reset the cached HTML files.

### Setting some sensible defaults

All of these are optional, but nice to have!

On your pull zone page, under General → Hostnames, go toggle “Force SSL” on for your domain to ensure that all requests use SSL. SSL/TLS is pretty standard these days, and many TLDs and websites use HSTS to enforce it, but no harm in enabling it here too.

DDoS protection comes out of the box, but we can set some other things up. First of all, go to Caching and then Origin Shield in the left menu on your pull zone, and activate Origin Shield. Select the location closest to your origin. This reduces load on your server, as bunny.net will cache everything in the Origin Shield location, and all edge locations will try that location first before hitting your server.

Next, go to Caching → General and scroll down. At the bottom of the page you can select Stale Cache: While Origin Offline and While Updating. This means bunny will keep serving cached content even if it is stale, if it can’t reach your origin, and that it will serve stale content while fetching the latest version. Both are nice to haves, nothing you have to enable, but provide a slightly better service to your users!

Next, let’s set up an Edge rule to redirect any requests to our automatically generated pull zone domain to our actual domain, to avoid confusing crawlers. On your pull zone, in the left menu, click Edge rules. 

1. Add edge rule.
2. Name it “Default domain redirect”.
3. Under actions, select Redirect.
4. For URL, input your URL plus the path variable. Eg for me it’s `https://jola.dev{{path}}` .
5. Status code: use the default 301.
6. For conditions, pick Match any and Request URL Match any.
7. Input `*://<slug>.b-cdn.net/*` replacing `<slug>` with the name given to your pull zone.
8. Save edge rule!

Now you should be able to go to `https://slug.b-cdn.net` for your pull zone and get redirected to your proper domain!

## Conclusion

This post just covers the very basics of getting set up on bunny.net. I haven’t even scratched the surface of edge rules, cache configuration, the Shield features for security and firewalls, video hosting and streaming, edge scripting and edge distributed containers, and much more.

I especially appreciate the great statistics, logs, and metrics you get out of the dashboard. You can even see every single request coming through to help you investigate issues, and clear feedback on what’s getting cached and not. I’m actively moving everything else over and I’m excited for the upcoming S3 compatible storage!

You should give [bunny.net](https://bunny.net?ref=f0l8865b7g) a try!
