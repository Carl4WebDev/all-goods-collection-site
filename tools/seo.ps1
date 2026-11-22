param(
  [string]$Root,
  [string]$BaseUrl = "https://carl4webdev.github.io/all-goods-collection-site/",
  [string]$LastMod = "2026-11-23"
)
$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$PESO = [string][char]0x20B1
$STORE_ID = "${BaseUrl}#store"
$SITE_ID = "${BaseUrl}#website"
$OWNER_ID = "${BaseUrl}#owner"
$OG_IMAGE = "${BaseUrl}og-image.png"

$pages = @(
  @{ f="index.html";         url="";                   type="WebPage";        crumbs=@() ; pri="1.0" }
  @{ f="shop.html";          url="shop.html";          type="CollectionPage"; crumbs=@(,@("Shop","shop.html")); pri="0.9" }
  @{ f="caps.html";          url="caps.html";          type="CollectionPage"; crumbs=@(@("Shop","shop.html"),@("Caps","caps.html")); pri="0.8" }
  @{ f="tees.html";          url="tees.html";          type="CollectionPage"; crumbs=@(@("Shop","shop.html"),@("Tees","tees.html")); pri="0.8" }
  @{ f="outerwear.html";     url="outerwear.html";     type="CollectionPage"; crumbs=@(@("Shop","shop.html"),@("Outerwear","outerwear.html")); pri="0.8" }
  @{ f="bags.html";          url="bags.html";          type="CollectionPage"; crumbs=@(@("Shop","shop.html"),@("Bags","bags.html")); pri="0.8" }
  @{ f="about.html";         url="about.html";         type="AboutPage";      crumbs=@(,@("About","about.html")); pri="0.7" }
  @{ f="service-areas.html"; url="service-areas.html"; type="WebPage";        crumbs=@(,@("Service Areas","service-areas.html")); pri="0.7" }
  @{ f="contact.html";       url="contact.html";       type="ContactPage";    crumbs=@(,@("Contact","contact.html")); pri="0.7" }
)

function Get-Text([string]$html) {
  $t = [regex]::Replace($html, '<[^>]+>', ' ')
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  return ([regex]::Replace($t, '\s+', ' ')).Trim()
}
function Esc([string]$s) { return [System.Net.WebUtility]::HtmlEncode($s) }

function New-Store {
  $cats = @("Caps","Tees","Outerwear","Bags") | ForEach-Object {
    [ordered]@{ "@type"="OfferCatalog"; name=$_; url="${BaseUrl}$($_.ToLower()).html" }
  }
  return [ordered]@{
    "@type" = "ClothingStore"
    "@id" = $STORE_ID
    name = "All Goods Collection"
    alternateName = "All Goods Cllctn"
    description = "Owner-run streetwear shop in Prk. Orchids, Brgy. Paquibato, Davao City selling Japan-surplus caps, tees, jackets, hoodies and bags. Any 3 items for ${PESO}999. Orders through Messenger; GCash accepted."
    url = $BaseUrl
    logo = "${BaseUrl}icon-512.png"
    image = $OG_IMAGE
    telephone = "+639317348736"
    address = [ordered]@{ "@type"="PostalAddress"; streetAddress="Prk. Orchids, Brgy. Paquibato"; addressLocality="Davao City"; addressRegion="Davao del Sur"; addressCountry="PH" }
    areaServed = @(
      [ordered]@{ "@type"="Place"; name="Paquibato, Davao City" },
      [ordered]@{ "@type"="City"; name="Davao City" }
    )
    openingHours = "Mo-Su"
    paymentAccepted = "GCash"
    currenciesAccepted = "PHP"
    priceRange = "${PESO}"
    founder = @{ "@id" = $OWNER_ID }
    contactPoint = [ordered]@{ "@type"="ContactPoint"; telephone="+639317348736"; contactType="sales"; areaServed="PH"; availableLanguage=@("English","Filipino","Cebuano"); url="https://m.me/ZCllctnss" }
    hasOfferCatalog = [ordered]@{ "@type"="OfferCatalog"; name="Japan-surplus streetwear"; itemListElement=@($cats) }
    makesOffer = [ordered]@{ "@type"="Offer"; name="Any 3 items for ${PESO}999"; price="999"; priceCurrency="PHP"; description="Mix any 3 caps, tees, outerwear or bags for ${PESO}999. Promos can change; confirm when ordering." }
    sameAs = @("https://www.facebook.com/ZCllctnss","https://www.instagram.com/w1nsloy_/","https://m.me/ZCllctnss")
  }
}

function New-Graph($p, [string]$html, [string]$title, [string]$desc) {
  $pageUrl = "${BaseUrl}$($p.url)"
  $graph = New-Object System.Collections.ArrayList
  [void]$graph.Add((New-Store))
  [void]$graph.Add([ordered]@{ "@type"="WebSite"; "@id"=$SITE_ID; url=$BaseUrl; name="All Goods Collection"; inLanguage="en-PH"; publisher=@{ "@id"=$STORE_ID } })
  [void]$graph.Add([ordered]@{ "@type"="Person"; "@id"=$OWNER_ID; name="Wenzly James"; jobTitle="Owner"; worksFor=@{ "@id"=$STORE_ID } })

  $items = New-Object System.Collections.ArrayList
  [void]$items.Add([ordered]@{ "@type"="ListItem"; position=1; name="Home"; item=$BaseUrl })
  $i = 2
  foreach ($c in $p.crumbs) { [void]$items.Add([ordered]@{ "@type"="ListItem"; position=$i; name=$c[0]; item="${BaseUrl}$($c[1])" }); $i++ }
  [void]$graph.Add([ordered]@{ "@type"="BreadcrumbList"; "@id"="${pageUrl}#breadcrumb"; itemListElement=@($items) })

  $h1 = [regex]::Match($html, '<h1[^>]*>(.*?)</h1>', 'Singleline')
  $webPage = [ordered]@{
    "@type" = $p.type; "@id" = "${pageUrl}#webpage"; url = $pageUrl; name = $title; description = $desc
    headline = (Get-Text $h1.Groups[1].Value)
    inLanguage = "en-PH"; isPartOf = @{ "@id"=$SITE_ID }; about = @{ "@id"=$STORE_ID }
    breadcrumb = @{ "@id"="${pageUrl}#breadcrumb" }
    primaryImageOfPage = [ordered]@{ "@type"="ImageObject"; url=$OG_IMAGE; width=1200; height=630 }
    dateModified = $LastMod
  }
  if ($p.type -eq "AboutPage") { $webPage.mainEntity = @{ "@id"=$STORE_ID } }
  if ($p.type -eq "ContactPage") { $webPage.mainEntity = @{ "@id"=$STORE_ID } }
  [void]$graph.Add($webPage)

  $faqs = [regex]::Matches($html, '<details><summary>(.*?)</summary><div class="ans">(.*?)</div></details>', 'Singleline')
  if ($faqs.Count -gt 0) {
    $q = @($faqs | ForEach-Object {
      [ordered]@{ "@type"="Question"; name=(Get-Text $_.Groups[1].Value); acceptedAnswer=[ordered]@{ "@type"="Answer"; text=(Get-Text $_.Groups[2].Value) } }
    })
    [void]$graph.Add([ordered]@{ "@type"="FAQPage"; "@id"="${pageUrl}#faq"; mainEntity=$q; isPartOf=@{ "@id"="${pageUrl}#webpage" } })
  }
  return [ordered]@{ "@context"="https://schema.org"; "@graph"=@($graph) }
}

foreach ($p in $pages) {
  $path = Join-Path $Root $p.f
  $html = [System.IO.File]::ReadAllText($path, $utf8)

  # remove previously generated / legacy SEO tags so the script is re-runnable
  $html = [regex]::Replace($html, '<!-- seo -->.*?<!-- /seo -->', '', 'Singleline')
  $html = [regex]::Replace($html, '<meta property="og:[^"]*" content="[^"]*">', '')
  $html = [regex]::Replace($html, '<script type="application/ld\+json">.*?</script>', '', 'Singleline')
  $html = $html.Replace('<html lang="en">', '<html lang="en-PH">')

  $title = Get-Text ([regex]::Match($html, '<title>(.*?)</title>').Groups[1].Value)
  $desc = [System.Net.WebUtility]::HtmlDecode([regex]::Match($html, '<meta name="description" content="([^"]*)">').Groups[1].Value)
  $pageUrl = "${BaseUrl}$($p.url)"
  $json = (New-Graph $p $html $title $desc) | ConvertTo-Json -Depth 20 -Compress

  $head = @"
<!-- seo -->
<link rel="canonical" href="$pageUrl">
<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1">
<meta name="author" content="All Goods Collection">
<meta name="geo.region" content="PH-DAS"><meta name="geo.placename" content="Davao City">
<meta property="og:type" content="website"><meta property="og:site_name" content="All Goods Collection"><meta property="og:locale" content="en_PH">
<meta property="og:url" content="$pageUrl"><meta property="og:title" content="$(Esc $title)"><meta property="og:description" content="$(Esc $desc)">
<meta property="og:image" content="$OG_IMAGE"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630"><meta property="og:image:alt" content="All Goods Collection: streetwear in Davao City, any 3 items for ${PESO}999">
<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="$(Esc $title)"><meta name="twitter:description" content="$(Esc $desc)"><meta name="twitter:image" content="$OG_IMAGE">
<link rel="icon" href="favicon.svg" type="image/svg+xml"><link rel="icon" href="favicon-32.png" sizes="32x32" type="image/png"><link rel="apple-touch-icon" href="apple-touch-icon.png"><link rel="manifest" href="site.webmanifest">
<link rel="sitemap" type="application/xml" href="sitemap.xml">
<script type="application/ld+json">$json</script>
<!-- /seo -->
"@
  $html = $html.Replace('</head>', "$head</head>")
  [System.IO.File]::WriteAllText($path, $html, $utf8)
  Write-Output "updated $($p.f)"
}

# sitemap.xml
$urls = ($pages | ForEach-Object { "  <url><loc>${BaseUrl}$($_.url)</loc><lastmod>$LastMod</lastmod><priority>$($_.pri)</priority></url>" }) -join "`n"
[System.IO.File]::WriteAllText((Join-Path $Root "sitemap.xml"), "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n$urls`n</urlset>`n", $utf8)

# robots.txt
[System.IO.File]::WriteAllText((Join-Path $Root "robots.txt"), "User-agent: *`nAllow: /`n`nSitemap: ${BaseUrl}sitemap.xml`n", $utf8)

# web manifest
$manifest = [ordered]@{ name="All Goods Collection"; short_name="All Goods"; start_url="./"; display="standalone"; background_color="#0c0b0a"; theme_color="#0c0b0a"; icons=@([ordered]@{ src="icon-192.png"; sizes="192x192"; type="image/png" }, [ordered]@{ src="icon-512.png"; sizes="512x512"; type="image/png" }) }
[System.IO.File]::WriteAllText((Join-Path $Root "site.webmanifest"), ($manifest | ConvertTo-Json -Depth 5), $utf8)
Write-Output "wrote sitemap.xml robots.txt site.webmanifest"
