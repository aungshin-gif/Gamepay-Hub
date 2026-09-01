/* Preserved product, plan, price, and payment data from the original website. */
window.GAMEPAY_DATA = (() => {
  "use strict";
const categories = ["All","AI & Productivity","Entertainment","VPN & Security","Creative Tools","Social & Services","More"];

    const products = [
      {
  id: "chatgpt",
  name: "ChatGPT",
  top: true,
  subtitle: "Tap to see prices",
  badge: "available",
  category: "AI",
  iconType: "image",
  icon: "chatgpt-icon.png",
  search: "chatgpt openai ai",
  description: "✅ Official access options are available.\n✔️ Own Mail option includes Full Warranty.\n✔️ History remains available with the official option.\n🔄 Renewal is available for eligible official access.\n❗️ CGPT GO stock can change; preorder may be required when unavailable.",
  plans: [
      { name: "👐 CGPT GO Official – 8$ Plan – 1 Month – 27000 Ks", price: 27000, ownMail: true, warranty: "Full Warranty", format: "Own Mail", note: "✅ Renew ရပါတယ်။\n✅ Own Mail ပိုပြေပါတယ်။\n✅ History မပျက်ပါ။\n✅ Full Warranty" },
      { name: "🌌 CHATGPT PLUS Official – 80$ Plan – 1 Month – 90000 Ks", price: 90000, ownMail: true, bestSeller: true, warranty: "Full Warranty", format: "Own Mail", note: "✅ Renew ရပါတယ်။\n✅ Own Mail ပိုပြေပါတယ်။\n✅ History မပျက်ပါ။\n✅ Full Warranty" },
      { name: "✴️ CHATGPT PLUS – Private – 1 Month – 30000 Ks", price: 30000, warranty: "25 days warranty", format: "Private account", note: "✅ 25 days warranty\n✅ 2 devices better" },
      { name: "☄️ CGPT GO – 3 Months – Preorder", price: 27000, outOfStock: true },
  ]
},
      {
  id: "canva",
  name: "Canva Pro",
  top: true,
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Editing",
  iconType: "image",
  icon: "Untitled-design-2025-01-28T101702.381.png",
  search: "canva design pro",
  description: "💥Premium Pro Private Planသည် Account ပေးမှာပါ။\n🔑 သည် own mailနဲ့သဘောတရားတူတူပါပဲ၊\n🔑 သည်ကိုယ်ပိုင်Canva accountထဲမှာ Redeemရုံပါပဲ",
  plans: [
    { name: "Canva Education – Own Mail – 1.5 Year – 5000 Ks",
      label: "Canva Education", type: "Own Mail", tier: "education",
      duration: "1.5 Year", price: 5000, ownMail: true, bestSeller: true },
    { name: "Canva Education – Code Redeem – 1.5 Years – 5000 Ks",
      label: "Canva Education", type: "Code Redeem", tier: "education",
      duration: "1.5 Years", price: 5000 },
    { name: "Canva Business – Own Mail – 1 Month – 6000 Ks",
      label: "Canva Business", type: "Own Mail", tier: "business",
      duration: "1 Month", price: 6000, ownMail: true },
    { name: "Canva Pro Individual – Private Acc – 1 Month – 7000 Ks",
      label: "Canva Pro Individual", type: "Private Acc", tier: "individual",
      duration: "1 Month", price: 7000, access: "private" }
  ]
      },
      {
  id: "capcut",
  name: "CapCut Pro",
  top: true,
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Editing",
  iconType: "image",
  icon: "IMG_20260307_045206_183.jpg",
  search: "capcut pro edit video",
  note: "🚫 Renew မရ\n✅ Full Warranty",
  warranty: "Full Warranty",
  description: "✔️ Full Warranty is included.\n🚫 Renewal is not available.\n🔐 Private and Share access are available as separate options.\n🛍 Select the account type you need before purchase.",
  plans: [
      { name: "CapCut Team – Private Acc – 7 Days – 2000 Ks",
        label: "CapCut Team", type: "Private Acc", tier: "team",
        duration: "7 Days", price: 2000, access: "private" },
      { name: "CapCut Team – Private Acc – 1 Month – 8000 Ks",
        label: "CapCut Team", type: "Private Acc", tier: "team",
        duration: "1 Month", price: 8000, access: "private", bestSeller: true },
      { name: "CapCut Pro Individual (crd 1200) – Private Acc – 34 Days – 12000 Ks",
        label: "CapCut Pro Individual (crd 1200)", type: "Private Acc", tier: "individual",
        duration: "34 Days", price: 12000, access: "private" },
      { name: "CapCut Individual – Private Acc – 6 Months – 50000 Ks",
        label: "CapCut Individual", type: "Private Acc", tier: "individual",
        duration: "6 Months", price: 50000, access: "private" },
      { name: "CapCut Team Head – Own Mail – 1 Month – Contact me",
        label: "CapCut Team Head", type: "Own Mail", tier: "team",
        duration: "1 Month", price: 0, custom: true, ownMail: true }
  ]
},
      {
  id: "gemini",
  name: "Gemini AI Pro",
  top: true,
  subtitle: "Tap to see prices",
  badge: "available",
  category: "AI",
  iconType: "image",
  icon: "file_00000000168071fa8d5d17512a7591b5.png",
  search: "gemini ai pro google ai",
  description: "✉️ Own Mail Invite includes Full Warranty and monthly renewal.\n👑 Family Manager access includes the warranty stated for the selected duration.\n🔗 Link access has No Warranty.\n🛍 Choose Own Mail, Family, or Link carefully before purchase.",
  plans: [
      { name: "Gemini AI Pro – Own Mail – 1 Month – 4000 Ks",
        label: "Gemini AI Pro", type: "Own Mail", tier: "pro",
        duration: "1 Month", price: 4000, ownMail: true, bestSeller: true },
      { name: "Gemini AI Pro – Own Mail – 2 Months – 7000 Ks",
        label: "Gemini AI Pro", type: "Own Mail", tier: "pro",
        duration: "2 Months", price: 7000, ownMail: true },
      { name: "Gemini AI Pro – Own Mail – 3 Months – 10000 Ks",
        label: "Gemini AI Pro", type: "Own Mail", tier: "pro",
        duration: "3 Months", price: 10000, ownMail: true },
      { name: "Gemini AI Pro – Own Mail – 4 Months – 12000 Ks",
        label: "Gemini AI Pro", type: "Own Mail", tier: "pro",
        duration: "4 Months", price: 12000, ownMail: true },
      { name: "Family Manager – Own Mail – 3 Months – 10000 Ks",
        label: "Family Manager", type: "Own Mail", tier: "family",
        duration: "3 Months", price: 10000, ownMail: true },
      { name: "Family Manager – Own Mail – 12 Months – 15000 Ks",
        label: "Family Manager", type: "Own Mail", tier: "family",
        duration: "12 Months", price: 15000, ownMail: true },
      { name: "Gemini Link – Own Mail – 1.5 Years – 8000 Ks",
        label: "Gemini Link", type: "Own Mail", tier: "link",
        duration: "1.5 Years", price: 8000, ownMail: true }
  ]
},
      {
  id: "zoom",
  name: "Zoom Pro",
  
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Services",
  iconType: "image",
  icon: "image.png",
  search: "zoom pro meeting video",
  description: "🔐 Private access is provided.\n🛍 Select the required duration before purchase.\n❗️Availability may change based on stock.",
  plans: [
      { name: "🔐 Private – 14 Days – 5000 Ks", price: 5000 },
      { name: "🔐 Private – 1 Month – 8000 Ks", price: 8000, bestSeller: true },
      { name: "🔐 Private – 2 Months – 15000 Ks", price: 15000 },
  ]
},
      {
  id: "hbomax",
  name: "HBO Max",
  top: true,             
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Streaming",
  iconType: "image",
  icon: "quality_restoration_20260510231859313.png",
  search: "hbo max premium streaming",
  description: "⚠️Each Profile 6000 ksဆိူတာက\n🌈Above 3 Pf ၀ယ်ရင်\n🥳1pfကို 6000 ksပဲကျမယ်ဆိုတယ့်‌သဘောပါ\n\n💥Headကတော့အတန်ဆုံးပါ။\n🌈1Pfကို 5000 ksပဲကျပါမယ်။",

  plans: [
    { name:"👤1 Profile - 8500 Ks\n1 Month", price:8500,bestSeller:true },
    { name:"👥2 Profiles - 13000 Ks\n1 Month", price:13000 },
    { name:"Each Profile - 6000 Ks\nAbove 3 Pf", price:6000 },
    { name:"🔥HBO Head - 25000 Ks\n1 Month", price:25000,bestSeller:true }
  ]
            },
      {
id: "picsart",
name: "PicsArt Pro",
subtitle: "Tap to see prices",
badge: "available",
category:"Editing",
iconType: "image",
icon: "IMG_20260307_042958_666.jpg",
search: "picsart photo edit",
description: "Private accountတွေပါ အာမခံပါတယ်။History/Projects အကုန် privateပါ။",
plans: [
{ name:"1 Month (👥Share) – 4000 Ks", price:4000},
{ name:"1 Month (🔐Private) – 5700 Ks", price:5700,bestSeller:true },
{ name:"3 Months – 14000 Ks", price:14000,outOfStock:true },
{ name:"1 Year – 50000 Ks", price:50000 },
{ name:"Own Mail - 1 Month – 24000 Ks", price:24000,outOfStock:true }
]
},
      {
  id: "hma_vpn",
  name: "HMA VPN",
  
  subtitle: "Tap to see prices",
  badge: "available",
  category: "VPN",
  iconType: "image",
  icon: "file_00000000fc3c71fab87726fc991b3be0.png",
  search: "hma vpn android mac pc",
  note: "✔️ Android / Mac / PC ရပါတယ်။\n❌ iOS မရပါ။\n⚠️ Only one device can be used in Share.\n📊 8-9 Devices can be used in Private.",
  description: "✅ Android / Mac / PC အသုံးပြုနိုင်သည်။\n❌ iOS မရပါ။\n⚠️ Share plan တွင် device 1 ခုသာ အသုံးပြုနိုင်သည်။\n📊 Private plan တွင် devices 8–9 ခု အသုံးပြုနိုင်သည်.",
  plans: [
      { name: "👥 1 Month – Share – 1400 Ks", price: 1400, access: "share" },
      { name: "🔐 1 Month – Private – 5000 Ks", price: 5000, access: "private", bestSeller: true },
      { name: "✉️ 1 Month – Own Mail – 6000 Ks", price: 6000, ownMail: true },
  ]
},
      {
  id: "vpn",
  name: "Express VPN",
  
  subtitle: "Tap to see prices",
  badge: "available",
  category: "VPN",
  iconType: "image",
  icon: "ExpressVPN-logo.png",
  search: "express vpn android mac pc ios",
  note: "✔️ Android / Mac / PC ရပါတယ်။\n✔️ iOS ရပါတယ်။\n🔐 All plans are same as private.",
  description: "✅ Android / Mac / PC / iOS အသုံးပြုနိုင်သည်။\n🔐 All plans use private-style access.\n🛍 Device count ကို plan အလိုက်ရွေးချယ်ပါ။",
  plans: [
      { name: "🔐 2 Months – 1 Device – 5000 Ks", price: 5000 },
      { name: "🔐 3 Months – 2 Devices – 7000 Ks", price: 7000, bestSeller: true },
      { name: "🔐 6 Months – 4 Devices – 11000 Ks", price: 11000 },
      { name: "🔐 12 Months – 6 Devices – 15000 Ks", price: 15000 },
  ]
},
      {
id: "telegram",
name: "Telegram Premium",
subtitle: "Tap to see prices",
badge: "available",
category:"Social",
iconType: "image",
icon: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNDAgMjQwIj48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9InQiIHgxPSIuNSIgeTE9IjAiIHgyPSIuNSIgeTI9IjEiPjxzdG9wIG9mZnNldD0iMCIgc3RvcC1jb2xvcj0iIzJBQUJFRSIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzIyOUVEOSIvPjwvbGluZWFyR3JhZGllbnQ+PC9kZWZzPjxjaXJjbGUgY3g9IjEyMCIgY3k9IjEyMCIgcj0iMTIwIiBmaWxsPSJ1cmwoI3QpIi8+PHBhdGggZD0iTTU0IDExOC41YzM1LTE1LjIgNTguMy0yNS4zIDcwLTMwLjIgMzMuMy0xMy45IDQwLjItMTYuMyA0NC43LTE2LjQgMSAwIDMuMi4yIDQuNyAxLjQgMS4yIDEgMS41IDIuMyAxLjcgMy4zLjIgMSAuNCAzLjEuMiA0LjgtMS44IDE5LjQtOS44IDY2LjMtMTMuOSA4OC0xLjcgOS4yLTUuMSAxMi4zLTguNCAxMi42LTcuMi43LTEyLjYtNC43LTE5LjUtOS4yLTEwLjgtNy4xLTE2LjktMTEuNS0yNy40LTE4LjQtMTIuMS04LTQuMy0xMi40IDIuNy0xOS42IDEuOC0xLjkgMzMuMi0zMC40IDMzLjgtMzMgLjEtLjMuMS0xLjUtLjYtMi4xLS43LS42LTEuNy0uNC0yLjUtLjItMS4xLjItMTguMyAxMS42LTUxLjcgMzQuMi00LjkgMy40LTkuMyA1LTEzLjMgNC45LTQuNC0uMS0xMi44LTIuNS0xOS00LjUtNy43LTIuNS0xMy44LTMuOC0xMy4zLTggLjMtMi4yIDMuMy00LjQgOS02Ljd6IiBmaWxsPSIjZmZmIi8+PC9zdmc+",
search: "telegram premium tg",
description:"Link planသည် linkကိုactivationလုပ်မှ premiumရတာပါ/Giftက usernameဆီပို့ပေးရတာပါ။premium featuresချင်းအကုန်အတူတူပါပဲ",
plans: [
{ name:"Login Method – 1 Month – 20500 Ks", price:20500,bestSeller:true },
{ name:"Gift Plan – 3 Months – 50000 Ks", price:50000 },
{ name:"Gift Plan – 6 Months – 67000 Ks", price:67000 },
{ name:"Gift Plan – 9 Months – 118000 Ks", price:118000 },
{ name:"Link Plan – 3 Months – 44000 Ks", price:44000,discount:true },
{ name:"Link Plan – 6 Months – 65000 Ks", price:65000 },
{ name:"Link Plan – 12 Months – 118000 Ks", price:118000 }
]
},
      {
  id: "adobe_cc",
  name: "Adobe Creative Cloud",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Editing",
  iconType: "image",
  icon: "Adobe_Creative_Cloud_rainbow_icon.svg.png",
  search: "adobe photoshop premiere creative cloud",
  description: "💫100% Private Account (My Mail)\n🔥 4000 Adobe credits\n💥 Renewed monthly method \n💥 Supports Mobile/PC/Mac",
  plans: [
    { name: "1 Month - 15000 Ks", price: 15000, bestSeller: true },
    { name: "2 Months - 25000 Ks", price: 25000 },
    { name: "3 Months - 39000 Ks", price: 39000 },
    { name: "6 Months - 35000 Ks", price: 35000 },
    { name: "1 Year - 100000 Ks (Stock rare)", price: 100000 }
  ]
},
      {
  id: "claude_ai",
  name: "Claude AI Plans",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "AI",
  iconType: "image",
  icon: "claude_logo_3ec57d87f2.svg",
  search: "claude ai pro max programming research own mail",
  note: "✅ Best For Programming\n✅ Full Warranty\n✅ Own Mail Type",
  warranty: "Full Warranty",
  format: "Own Mail",
  description: "✔️ Best for programming and research.\n✔️ Full Warranty\n✔️ Own Mail Type\n🔼 Claude API coming soon.",
  plans: [
    { name: "Claude PRO – 1 Month – 93000 Ks", price: 93000, ownMail: true, bestSeller: true },
    { name: "Claude MAX – 1 Month – 500000 Ks", price: 500000, ownMail: true }
  ]
},
      {
  id: "cursor",
  name: "Cursor AI Plans",
  top: true,
  subtitle: "Tap to see prices",
  badge: "available",
  category: "AI",
  iconType: "image",
  icon: "images (1).png",
  search: "cursor ai pro plus coding editor own mail",
  description: "✔️ Full Warranty\n✔️ Own Mail Type\n✔️ Best for coding with AI agents.",
  format: "On your Own mail",
  warranty: "Full Warranty",
  plans: [
    {
      name: "Cursor Pro – 1 Month – 92000 Ks",
      price: 92000, ownMail: true, bestSeller: true,
      duration: "1 Month",
      format: "On your Own mail",
      warranty: "Full Warranty",
      note: "Features\n✓ Extended limits on Agent\n✓ Generous limits for Grok\n✓ Access to frontier models\n✓ MCPs, skills, and hooks\n✓ Cloud agents\n✓ Budget on usage billing"
    },
    {
      name: "Cursor Plus – 1 Month – 285000 Ks",
      price: 285000, ownMail: true,
      duration: "1 Month",
      format: "On your Own mail",
      warranty: "Full Warranty",
      note: "Features\n✓ 3x Pro limits on Agent\n✓ Generous limits for Grok\n✓ Access to frontier models\n✓ MCPs, skills, and hooks\n✓ Cloud agents\n✓ Bugbot on usage-based billing\n✓ Access to Grok Bot"
    }
  ]
},
      {
  id: "grok",
  name: "Grok AI Plans",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "AI",
  iconType: "image",
  icon: "grok-icon.webp",
  search: "grok ai super grok plus heavy",
  description: "💥 Full Warranty ပါ။\n✔️ Renewal ရပါတယ်။\n✔️ Own Mail ပိုပြေပါတယ်။\n🛍 Access is provided on your account.",
  plans: [
    { name: "Super Grok – 1 Month – 58000 Ks", price: 58000, ownMail: true, bestSeller: true },
    { name: "Super Grok – 3 Months – 190000 Ks", price: 190000, ownMail: true },
    { name: "SuperGrok Plus – 1 Month – 480000 Ks", price: 480000, ownMail: true },
    { name: "SuperGrok Heavy – 1 Month – DM", price: 0, ownMail: true }
  ]
},
      {
  id: "perplexity",
  name: "Perplexity AI Pro",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "AI",
  iconType: "image",
  icon: "perplexity-ai-icon.png",
  search: "perplexity ai pro own mail",
  description: "💥 Full Warranty ပါ။\n✔️ Renewal ရပါတယ်။\n✔️ Own Mail ပိုပြေပါတယ်။\n🛍 Access is provided on your account.",
  plans: [
    { name: "Perplexity AI Pro – 1 Month – 43000 Ks", price: 43000, ownMail: true, bestSeller: true }
  ]
},
      {
  id: "kling_ai",
  name: "Kling AI",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "AI",
  iconType: "image",
  icon: "images (5).jpeg",
  search: "kling ai standard pro premier ultra credits",
  description: "✅ Can Renew, but not with this promotional price.\n✅ Own Mail Plan\n✅ Full Warranty\n🔥 Credit options are available separately.",
  plans: [
    { name: "Standard Plan – 1 Month – 40000 Ks", price: 40000, ownMail: true },
    { name: "Pro Plan – 1 Month – 130000 Ks", price: 130000, ownMail: true, bestSeller: true },
    { name: "Premier Plan – 1 Month – 320000 Ks", price: 320000, ownMail: true },
    { name: "Ultra Plan – 1 Month – 590000 Ks", price: 590000, ownMail: true },
    { name: "330 Credits – 26500 Ks", price: 26500 },
    { name: "660 Credits – 45500 Ks", price: 45500 },
    { name: "1320 Credits – 92500 Ks", price: 92500 },
    { name: "3500 Credits – 230000 Ks", price: 230000 }
  ]
},
      {
  id: "suno_ai",
  name: "Suno AI Plans",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "AI",
  iconType: "image",
  icon: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIj48cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgcng9IjIyIiBmaWxsPSIjMGIwYjBmIi8+PGcgZmlsbD0iI2ZmZiI+PHJlY3QgeD0iMjIiIHk9IjQyIiB3aWR0aD0iNyIgaGVpZ2h0PSIxNiIgcng9IjMuNSIvPjxyZWN0IHg9IjM1IiB5PSIzMiIgd2lkdGg9IjciIGhlaWdodD0iMzYiIHJ4PSIzLjUiLz48cmVjdCB4PSI0OCIgeT0iMjIiIHdpZHRoPSI3IiBoZWlnaHQ9IjU2IiByeD0iMy41Ii8+PHJlY3QgeD0iNjEiIHk9IjM0IiB3aWR0aD0iNyIgaGVpZ2h0PSIzMiIgcng9IjMuNSIvPjxyZWN0IHg9Ijc0IiB5PSI0NCIgd2lkdGg9IjciIGhlaWdodD0iMTIiIHJ4PSIzLjUiLz48L2c+PC9zdmc+",
  search: "suno ai pro premier music",
  description: "✅ Own Mail\n✅ Full Warranty\n🎵 Pro and Premier access with plan-specific credits and features.",
  plans: [
    { name: "Pro Plan – 1 Month – 50000 Ks", price: 50000, ownMail: true, bestSeller: true },
    { name: "Premier Plan – 1 Month – 140000 Ks", price: 140000, ownMail: true }
  ]
},
{
id: "gitHub copilot",
name : "GitHub Copilot Pro/Plus/Max",
subtitle: "Tap to see prices",
  badge: "available",
  category: "AI",
  iconType: "image",
  icon: "images.png",
  search: " GitHub copilot own mail",
  description: "💥 Full Warranty ပါ။\n✔️ Renewal ရပါတယ်။\n✔️ Own Mail ပိုပြေပါတယ်။\n🛍 Access is provided on your account.",
plans: [
    { name: "GitHub Copilot Pro – 1 Month – 48000 Ks", price: 48000, ownMail: true, bestSeller: true },
    { name: "GitHub Copilot Pro+ – 1 Month – 178000 Ks", price: 178000, ownMail: true },
    { name: "GitHub Copilot Max – 1 Month – 480000 Ks", price: 480000, ownMail: true }
  ]
},
      {
  id: "x_premium",
  name: "X (Twitter) Premium",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Social",
  iconType: "image",
  icon: "twitter-new-logo-x-icon-design_1017-45424.jpg",
  search: "x twitter premium plus",
  description: "💥 Full Warranty ပါ။\n✔️ Access on your account.\n✔️ Premium features are included.",
  plans: [
    { name: "X Premium – 1 Month – 30000 Ks", price: 30000, ownMail: true, bestSeller: true },
    { name: "X Premium Plus – 1 Month – 135000 Ks", price: 135000, ownMail: true }
  ]
},
      {
  id: "whatsapp_plus",
  name: "WhatsApp Plus",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Social",
  iconType: "image",
  icon: "images (2).jpeg",
  search: "whatsapp plus",
  description: "✅ WhatsApp Plus access is provided.\n🛍 Select your required duration before purchase.",
  plans: [
    { name: "WhatsApp Plus – 1 Month – 22000 Ks", price: 22000, bestSeller: true }
  ]
},
      {
  id: "whatsapp_accounts",
  name: "WhatsApp Accounts",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Social",
  iconType: "image",
  icon: "images (2).jpeg",
  search: "whatsapp accounts usa canada france number",
  description: "✅ Ready account numbers are available.\n🛍 Select the country number you need before purchase.",
  plans: [
    { name: "USA Number – 20000 Ks", price: 20000 },
    { name: "Canada Number – 21000 Ks", price: 21000 },
    { name: "France Number – 25000 Ks", price: 25000 }
  ]
},
      
      {
  id: "netflix",
  name: "Netflix Premium",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Video",
  iconType: "image",
  icon: "netflix-icon.png",
  search: "netflix premium 4k ultra hd hdr",
  description: "🌈Head Accountတခုမှာ\n🌈5 Profileပါပါတယ်။",
  plans: [
    { name: "🌈(1 Profile) -8000 Ks\n1 Month", price: 8000, bestSeller: true },
    { name: "🌈(3 Profiles) - 19000 Ks\n1 Month", price: 19000 },
    { name: "🌈(4 Profiles) - 25000 Ks\n1 Month", price: 25000 },
    { name: "🌈(Head) - 38000 Ks\n1 Month", price: 38000 }

  ]
      },
      {
  id: "spotify",
  name: "Spotify",
  top: true,
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Music",
  iconType: "image",
  icon: "quality_restoration_20260510232104714.png",
  search: "spotify music premium individual family own mail",
  note: "❗️ Individual Plan က သက်တမ်းတိုးမရပါ။\n✔️ Family ကတော့ သက်တမ်းတိုးရပါတယ်။\n🔼 Own mail လည်းရပါတယ်။\n🛍 ဒီဈေးတွေပါပဲ။",
  description: "❗ Some options cannot be renewed.\n✔ Renewal is available only for eligible options.\n🔼 Own email may be available.\n🛍 Check the selected plan details before purchase.",
  plans: [
    { name: "🔥 Individual Plan — 1 Month — 10000 Ks", price: 10000 },
    { name: "🔥 Individual Plan — 2 Months — 15000 Ks", price: 15000 },
    { name: "✨ Family Plan — 3 Months — 18000 Ks", price: 18000, bestSeller: true }
  ]
},
      {
  id: "tidal_music",
  name: "Tidal Music",
  top: true,
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Music",
  iconType: "image",
  icon: "tidal-logo-rounded-hd-free-png.png",
  search: "tidal music premium individual family own mail",
  note: "❗️ Individual Plan က သက်တမ်းတိုးမရပါ။\n✔️ Family ကတော့ သက်တမ်းတိုးရပါတယ်။\n🔼 Own mail လည်းရပါတယ်။\n🛍 ဒီဈေးတွေပါပဲ။",
  description: "❗ Some options cannot be renewed.\n✔ Renewal is available only for eligible options.\n🔼 Own email may be available.\n🛍 Check account access details before purchase.",
  plans: [
    { name: "💥 Individual Plan — 1 Month — 8000 Ks", price: 8000 },
    { name: "💥 Family Plan — 1 Month — 8000 Ks", price: 8000, bestSeller: true },
    { name: "💥 Family Plan — 2 Months — 10000 Ks", price: 10000 }
  ]
},
      {
  id: "youtube_music",
  name: "YouTube Music",
  top: true,
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Music",
  iconType: "image",
  icon: "unnamed (1).jpg",
  search: "youtube music ready made private own mail invite",
  note: "❌ သက်တမ်းတိုးမရပါ။\n✔️ Own mail ပါ။",
  description: "❌ 1 Month option cannot be renewed.\n✔ 3 Months Own Mail option can be renewed.\n❗ Availability may change.\n🛍 Choose a plan before purchase.",
  plans: [
    { name: "YouTube Music – Your Mail – 1 Month – 7000 Ks", price: 7000, ownMail: true, bestSeller: true }
  ]
},
      {
  id: "soundcloud_go",
  name: "SoundCloud Go",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Music",
  iconType: "image",
  icon: "488-3.jpg",
  search: "soundcloud go music private ready made account",
  note: "❌ သက်တမ်းတိုးမရပါ။\n✔️ Private Ready made Acc ပေးမှာပါ။",
  description: "❌ Renewal is not available.\n✔ A ready-made account will be delivered.\n🛍 Check access details after delivery.",
  plans: [
    { name: "SoundCloud Go — 1 Month — 8000 Ks", price: 8000 }
  ]
},
      {
  id: "qobuz_music",
  name: "Qobuz Music",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Music",
  iconType: "image",
  icon: "a.jpg",
  search: "qobuz music private ready made account",
  note: "❌ သက်တမ်းတိုးမရပါ။\n✔️ Private Ready made Acc ပေးမှာပါ။",
  description: "❌ Renewal is not available.\n✔ A ready-made account will be delivered.\n🛍 Check access details before purchase.",
  plans: [
    { name: "Qobuz Music — 1 Month — 8000 Ks", price: 8000 }
  ]
},
      {
  id: "apple_music",
  name: "Apple Music (Android)",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Music",
  iconType: "image",
  icon: "apps.62962.14205055896346606.c235e3d6-fbce-45bb-9051-4be6c2ecba8f.png",
  search: "apple music android individual family own mail",
  note: "❗️ Individual Plan က သက်တမ်းတိုးမရပါ။\n✔️ Family ကတော့ သက်တမ်းတိုးရပါတယ်။\n🔼 Own mail လည်းရပါတယ်။\n🛍 ဒီဈေးတွေပါပဲ။",
  description: "❗ Some options cannot be renewed.\n✔ Renewal is available only for eligible options.\n🔼 Own email may be available.\n🛍 Confirm Android compatibility before purchase.",
  plans: [
    { name: "💥 Individual Plan — 1 Month — 6000 Ks", price: 6000 },
    { name: "💥 Family Plan — 1 Month — 6000 Ks", price: 6000, bestSeller: true },
    { name: "💥 Family Plan — 2 Months — 9000 Ks", price: 9000 },
    { name: "💥 Family Plan — 3 Months — 11000 Ks", price: 11000 }
  ]
},
      {
  id: "youtube",
  name: "YouTube Premium",
  top: true,
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Video",
  iconType: "image",
  icon: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMTgwIj48cGF0aCBkPSJNMjUwLjMgMjguMUMyNDcuNCAxNyAyMzguNyA4LjMgMjI3LjYgNS40IDIwNy41IDAgMTI4IDAgMTI4IDBTNDguNSAwIDI4LjQgNS40QzE3LjMgOC4zIDguNiAxNyA1LjcgMjguMSAwIDQ4LjMgMCA5MCAwIDkwczAgNDEuNyA1LjcgNjEuOWMyLjkgMTEuMSAxMS42IDE5LjggMjIuNyAyMi43QzQ4LjUgMTgwIDEyOCAxODAgMTI4IDE4MHM3OS41IDAgOTkuNi01LjRjMTEuMS0yLjkgMTkuOC0xMS42IDIyLjctMjIuN0MyNTYgMTMxLjcgMjU2IDkwIDI1NiA5MHMwLTQxLjctNS43LTYxLjl6IiBmaWxsPSIjRkYwMDAwIi8+PHBhdGggZD0iTTEwMi40IDEyOC42IDE2OC44IDkwbC02Ni40LTM4LjZ6IiBmaWxsPSIjZmZmIi8+PC9zdmc+",
  search: "youtube premium subscription",
  description: "✉️ Own Mail/Invite option includes Full Warranty.\n🔗 Link access has No Warranty.\n👑 Family Head can invite up to 5 accounts.\n🛍 Select the access type carefully before purchase.",
  plans: [
      { name: "🌐 Individual – Private Account – 1 Month – 6500 Ks", price: 6500 },
      { name: "🌐 Individual – 3 Months – 20000 Ks", price: 20000, ownMail: true, bestSeller: true },
      { name: "✉️ Individual – Invite Your Mail – 1 Month – 7000 Ks", price: 7000, ownMail: true },
      { name: "👑 Family Head Account – 1 Month – 30000 Ks", price: 30000 }
  ]
},
      {
id: "disney",
name: "Disney+",
subtitle: "Tap to see prices",
badge: "available",
category:"Video",
iconType: "image",
icon: "disney_1xun.3840.webp",
search: "disney plus subscription",
description:"",
plans: [
{ name:"Disney+ Premium - 1 Month - 7000 Ks", price:7000 },
{ name:"Disney+ Duo - 1 Month - 8000 Ks", price:8000 },
{ name:"Disney+ Trio - 1 Month - 10000 Ks", price:10000 },

{ name:"Disney+ Premium - 3 Months - 8500 Ks", price:8500 },
{ name:"Disney+ Duo - 3 Months - 12000 Ks", price:12000 },
{ name:"Disney+ Trio - 3 Months - 15000 Ks", price:15000 },

{ name:"Disney+ Premium - 12 Months - 20000 Ks", price:20000 },
{ name:"Disney+ Duo - 12 Months - 22000 Ks", price:22000 },
{ name:"Disney+ Trio - 12 Months - 30000 Ks", price:30000 }
]
},
      {
id: "prime",
name: "Prime Video",
subtitle: "Tap to see prices",
badge: "available",
category:"Video",
iconType: "image",
icon: "Prime-Video.webp",
search: "amazon prime video",
description:"Private profiles and full-time warranty available.",
plans: [
{ name:"Premium – 1 Month – 8000 Ks", price:8000, bestSeller:true },
{ name:"Premium – 6 Months – 20000 Ks", price:20000 }
]
},
      {
  id: "bigo",
  name: "Bigo Live",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Video",
  iconType: "image",
  icon: "8bb1f032b24ebd0dc4eb601a22dc622f.jpg",
  search: "bigo live diamonds recharge",
  description: "🎥 Bigo Live Diamonds ဝယ်ယူနိုင် | Live streaming support | Fast top-up service | Safe & reliable",
  plans: [
    { name: "50 Diamonds 💎 - 4200 Ks", price: 4200 },
    { name: "100 Diamonds 💎 - 8500 Ks", price: 8500 },
    { name: "150 Diamonds 💎 - 12980 Ks", price: 12980 },
    { name: "200 Diamonds 💎 - 16950 Ks", price: 16950 },
    { name: "250 Diamonds 💎 - 21200 Ks", price: 21200 },
    { name: "300 Diamonds 💎 - 25300 Ks", price: 25300 },
    { name: "400 Diamonds 💎 - 34200 Ks", price: 34200 },
    { name: "500 Diamonds 💎 - 42300 Ks", price: 42300 },
    { name: "750 Diamonds 💎 - 63200 Ks", price: 63200 },
    { name: "1000 Diamonds 💎 - 84580 Ks", price: 84580 },
    { name: "2000 Diamonds 💎 - 168700 Ks", price: 168700 },
    { name: "3000 Diamonds 💎 - 265060 Ks", price: 265060 }
  ]
},
      {
  id: "facebook_service",
  name: "Facebook Service",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Services",
  iconType: "image",
  icon: "8379988-768x768.jpg",
  search: "facebook followers reactions views",
  description: "🌐Global Nameတွေပါ။\n🌐Global Data တွေပါ။",
  plans: [

        // Followers (No Refill)
    {
  name: "👥Followers(NoRefill)⚡",
  price: 5000,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Followers"
    },
    // Followers (Refill / High Quality)
{
  name: "👥Followers (Refill / High Quality)🔥",
  price: 7000,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Followers"
},
// Post Reactions (30 Days)
{
  name: "👍Like 💥",
  price: 5000,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Reactions",
  duration: "30 Days"
},
{
  name: "❤️Love 💥",
  price: 5000,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Reactions",
  duration: "30 Days"
},
{
  name: "😂Haha 💥",
  price: 5000,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Reactions",
  duration: "30 Days"
},
{
  name: "😮Wow 💥",
  price: 5000,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Reactions",
  duration: "30 Days"
},
{
  name: "😢Sad 💥",
  price: 5000,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Reactions",
  duration: "30 Days"
},
{
  name: "😡Angry 💥",
  price: 5000,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Reactions",
  duration: "30 Days"
},

// Mixed
{
  name: "👍❤️🤣🥲😯 Mixed Reactions 💥",
  price: 6500,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Reactions",
  duration: "30 Days"
},
{
  name: "👥👁️Story Views 💯",
  price: 6500,
  custom: true,
  baseAmount: 1000,
  minAmount: 500,
  unit: "Views"
},
    
// Facebook Ads
{
  name: "📢 Facebook Ads 1️⃣💲 ⏩ 5600 Ks",
  price: 5600,
  custom: true,
  baseAmount: 1,
  minAmount: 5,
  unit: "USD Ads"
},
    

  ]
 },
      {
  id: "🪙tiktok_coins_promote",
  name: "TikTok Coins & Promote",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Services",
  iconType: "image",
  icon: "1000_F_1535651940_vg2Yd6yUBMgpL49j6H9FTK7Y111hHCmk.jpg",
  search: "tiktok coins promote",
  minAmount: 100, // 👉 Minimum
  description: "🪙Coin မဝယ်သူများအတွက် Video Link ပေးရုံဖြင့် 1$ မှစ၍ Promote လုပ်နိုင်ပါသည်🔥",
  plans: [
    // TikTok Coins
    { name: "🪙Titok Coins 🪙", price: 5200, custom: true, baseAmount: 100,minAmount: 100, unit: "Coins", noDuration: true },

    // TikTok Promote
    { name: "🔥📈 TikTok Promote 💲💲", price: 6000, custom: true, baseAmount: 1,minAmount: 1, unit: "USD Promote", noDuration: true }
    
  ]
      },
      {
id: "wink",
name: "Wink VIP",
subtitle: "Tap to see prices",
badge: "available",
category:"Editing",
iconType: "image",
icon: "41054661-1713936918042-110deb4aa0105.jpg",
search: "wink video editor vip",
description:"have only 1 stock for china region",
plans: [
{ name:"China Region – 1 Month – 4500 Ks", price:4500,outOfStock:true },
{ name:"👥Global Region – 1 Month – 7000 Ks (Share) – 1 Device", price:8000 },
{ name:"🔐Global Region – 1 Month – 18000 Ks (Private) – 3 Devices", price:18000 },
{ name:"🔐Global Region – 1 Year – 160000 Ks (Private) – 3 Devices", price:160000 }
]
},
      {
  id: "meitu",
  name: "Meitu VIP/SVIP",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Editing",
  iconType: "image",
  icon: "FB_IMG_1774857673765.jpg",
  search: "meitu vip svip beauty edit",
  descriptionPages: [
  {
    title: "VIP အကြောင်း",
    text:
`⭐️ VIP Plan

🔥 Meitu mobile app ထဲက
paid features တွေကို အဓိကအသုံးပြုနိုင်တဲ့ plan ပါ။

📱 ဖုန်းနဲ့ edit လုပ်တဲ့
normal users တွေအတွက်
ပိုသင့်တော်ပါတယ် 👍`
  },

  {
    title: "SVIP အကြောင်း",
    text:
`👑 SVIP Plan

✅ VIP ရဲ့ upgraded version ဖြစ်ပြီး

📱 Mobile
💻 Web
🖥 Desktop

အထိ multi-device အသုံးပြုနိုင်ပါတယ် 😏

✨ ဒါ့အပြင် —

✔ Paid Templates
✔ Premium Fonts
✔ Advanced Paid Features
✔ Extra Materials & Effects
✔ HD / Watermark-Free Download
✔ Ad-Free Experience
✔ Batch Processing Trial

စတဲ့ extra premium rights တွေလည်း
ပါဝင်ပါတယ် 🔍`
  }
],
  plans: [
    { name: "👥VIP Plan (Share account) - 1 Month - 8000 Ks", price: 8000 },
    { name: "🔐VIP Plan (Private account) - 1 Month - 12000 Ks", price: 12000 },
    { name: "🔐VIP Plan (Private account) - 1 Year - 98000 Ks", price: 98000 },

    { name: "👥SVIP Plan (Share account) - 1 Month - 15000 Ks", price: 15000 },
    { name: "🔐SVIP Plan (Private account) - 1 Month - 22000 Ks", price: 22000 },
    { name: "🔐SVIP Plan (Private account) - 3 Months - 53000 Ks", price: 53000 },
    { name: "🔐SVIP Plan (Private account) - 1 Year - 160000 Ks", price: 160000 },

    { name: "✉️Own Mail VIP Plan - 1 Month - 12500 Ks", price: 12500 },
    { name: "✉️Own Mail SVIP Plan - 1 Month - 21000 Ks", price: 21000 },
    { name: "✉️Own Mail SVIP Plan - 3 Months - 54000 Ks", price: 54000 },
    { name: "✉️Own Mail SVIP Plan - 1 Year - 165000 Ks", price: 165000 }
  ]
},
      {
id: "steam",
name: "Steam Wallet",
subtitle: "Tap to see prices",
badge: "available",
category:"Gift",
iconType: "image",
icon: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIj48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9InMiIHgxPSIwIiB5MT0iMCIgeDI9IjEiIHkyPSIxIj48c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiMxYjI4MzgiLz48c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiMwZTE3MjAiLz48L2xpbmVhckdyYWRpZW50PjwvZGVmcz48Y2lyY2xlIGN4PSI1MCIgY3k9IjUwIiByPSI1MCIgZmlsbD0idXJsKCNzKSIvPjxwYXRoIGQ9Ik02NC41IDI0Yy05IDAtMTYuMyA3LjItMTYuNCAxNi4yTDM3LjYgNTUuNGMtLjctLjEtMS40LS4yLTIuMS0uMi0yLjYgMC01IC44LTcgMi4yTDE2IDUxLjl2MTguNGw5LjYgNGMxLjUgNC4yIDUuNSA3LjIgMTAuMiA3LjIgNS45IDAgMTAuNy00LjcgMTAuOS0xMC41bDE0LjktMTAuN2guM2M5IDAgMTYuNC03LjQgMTYuNC0xNi40UzczLjUgMjQgNjQuNSAyNHptLTI4LjcgNTEuNWMtMy4zIDAtNi4yLTItNy40LTQuOGw0LjggMmMyLjUgMS4xIDUuNC0uMSA2LjQtMi42IDEuMS0yLjUtLjEtNS40LTIuNi02LjRsLTQuOC0yYzEtLjQgMi4yLS42IDMuNi0uMyAxLjkuMyAzLjUgMS40IDQuNiAyLjkgMSAxLjYgMS40IDMuNSAxIDUuMy0uNyAzLjQtMy44IDUuOS01LjYgNS45em0yOC43LTE5LjZjLTYgMC0xMC45LTQuOS0xMC45LTEwLjlTNTguNSAzNCA2NC41IDM0czEwLjkgNC45IDEwLjkgMTAuOS00LjkgMTEtMTAuOSAxMXptMC0xOS4xYy00LjUgMC04LjIgMy43LTguMiA4LjJzMy43IDguMiA4LjIgOC4yIDguMi0zLjcgOC4yLTguMi0zLjctOC4yLTguMi04LjJ6IiBmaWxsPSIjZmZmIi8+PC9zdmc+",
search: "steam wallet game card",
description:"",
plans: [
{ name:"5 USD - 23200 Ks", price:23200 },
{ name:"10 USD - 45000 Ks", price:45000 },
{ name:"20 USD - 90000 Ks", price:90000 },
{ name:"25 USD - 113000 Ks", price:113000 },
{ name:"30 USD - 137000 Ks", price:137000 },
{ name:"35 USD - 157000 Ks", price:157000 },
{ name:"50 USD - 228000 Ks", price:228000 },
{ name:"100 USD - 460000 Ks", price:460000 }
]
},
      {
  id: "duolingo",
  name: "Duolingo",
  subtitle: "Tap to see prices",
  badge: "available",
  category: "Services",
  iconType: "image",
  icon: "duolingo-duo-owl-logo-2022.jpg",
  search: "duolingo individual family own mail",
  description: "✅ Full Warranty\n✅ Own Mail\n🛍 Select the required account type before purchase.",
  plans: [
    { name: "Individual Plan – 1 Month – 5000 Ks", price: 5000, ownMail: true, bestSeller: true },
    { name: "Family Plan – Coming Soon", price: 0, outOfStock: true }
  ]
},
      {
  id: "nordvpn",
  name: "Nord VPN",
  
  subtitle: "Tap to see prices",
  badge: "available",
  category: "VPN",
  iconType: "image",
  icon: "NordVPN_Logo_square.svg (1).png",
  search: "nord vpn android mac pc ios",
  note: "✔️ Android / Mac / PC ရပါတယ်။\n✔️ iOS ရပါတယ်။\n⚠️ Only one device can be used in Share.\n📊 8-9 Devices can be used in Private.",
  description: "✅ Android / Mac / PC / iOS အသုံးပြုနိုင်သည်။\n⚠️ Share plan တွင် device 1 ခုသာ အသုံးပြုနိုင်သည်။\n📊 Private plan တွင် devices 8–9 ခု အသုံးပြုနိုင်သည်.",
  plans: [
      { name: "👥 2 Months – Share – 8000 Ks", price: 8000 },
      { name: "🔐 2 Months – Private – 15000 Ks", price: 15000 },
      { name: "👥 3 Months – Share – 12000 Ks", price: 12000 },
      { name: "🔐 3 Months – Private – 22000 Ks", price: 22000, bestSeller: true },
  ]
},
      {
  id: "onevpn",
  name: "One VPN",
  
  subtitle: "Tap to see prices",
  badge: "available",
  category: "VPN",
  iconType: "image",
  icon: "unnamed (1).webp",
  search: "one vpn android mac pc",
  note: "✔️ Android / Mac / PC ရပါတယ်။\n❌ iOS မရပါ။\n⚠️ Only one device can be used in Share.\n📊 8-9 Devices can be used in Private.",
  description: "✅ Android / Mac / PC အသုံးပြုနိုင်သည်။\n❌ iOS မရပါ။\n⚠️ Share plan တွင် device 1 ခုသာ အသုံးပြုနိုင်သည်။\n📊 Private plan တွင် devices 8–9 ခု အသုံးပြုနိုင်သည်.",
  plans: [
      { name: "👥 1 Month – Share – 1600 Ks", price: 1600 },
      { name: "🔐 1 Month – Private – 6000 Ks", price: 6000, bestSeller: true },
  ]
},
      {
  id: "surfshark",
  name: "Surfshark VPN",
  
  subtitle: "Tap to see prices",
  badge: "available",
  category: "VPN",
  iconType: "image",
  icon: "0E7JiQw5SPOUbKbn59GQ.png",
  search: "surfshark vpn android mac pc ios",
  note: "✔️ Android / Mac / PC ရပါတယ်။\n✔️ iOS ရပါတယ်။\n⚠️ Only one device can be used in Share.\n📊 8-9 Devices can be used in Private.",
  description: "✅ Android / Mac / PC / iOS အသုံးပြုနိုင်သည်။\n⚠️ Share plan တွင် device 1 ခုသာ အသုံးပြုနိုင်သည်။\n📊 Private plan တွင် devices 8–9 ခု အသုံးပြုနိုင်သည်.",
  plans: [
      { name: "👥 2 Months – Share – 6000 Ks", price: 6000 },
      { name: "🔐 2 Months – Private – 28000 Ks", price: 28000, bestSeller: true },
  ]
},
    ];

    const paymentMethods = ["KPay","Wave","AYA","UAB","Binance"];
    const paymentMeta = {
      KPay: {label:"KBZPay", logo:"unnamed.png"},
      Wave: {label:"WavePay", logo:"unnamed (1).png"},
      AYA: {label:"AYA Pay", logo:"unnamed (2).png"},
      UAB: {label:"UABPay", logo:"uabpay-black.png"},
      Binance: {label:"Binance", logo:"23.png"}
    };
    const paymentAccounts = {
  KPay: {
    phone: "09795687480",
    name: "Aung Shin Thant Htun"
  },
  Wave: {
    phone: "09795687480",
    name: "Aung Shin Thant Htun"
  },
  UAB: {
    phone: "09795687480",
    name: "Aung Shin Thant Htun"
  },
  AYA: {
    phone: "09795687480",
    name: "Aung Shin Thant Htun"
  }
};

  return {
    telegramUsername: "angsthtun",
    telegramChannel: "gamepaydyet",
    categories,
    products,
    paymentMethods,
    paymentMeta,
    paymentAccounts
  };
})();

