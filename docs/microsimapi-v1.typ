#import "@preview/charged-ieee:0.1.3": ieee

#show: ieee.with(
  title: [An API For Microsimulation Models],
  abstract: [This note describes a simple general Application Programming Interface (API)
    for controlling microsimulation models.
  ],
  authors: (
    (
      name: "Graham Stark",
      department: [Social Work and Social Policy],
      organization: [University of Northumbria],
      location: [Newcastle, UK],
      email: "graham.stark@northumbria.ac.uk",
    ),
  ),
  paper-size: "a4",
  index-terms: ("Microsimulation", "APIs"),
  bibliography: bibliography("API.bib"),
  figure-supplement: [Fig.],
)

#show link: underline

#show table.cell.where(x: 2): set text(style: "italic", size: 7pt)
#show table.cell.where(x: 1): set text(size: 4pt, font: "JuliaMono")
#show table.cell.where(x: 0): set text(size: 7pt)

#set table(
  columns: (8em, auto, auto),
  align: (left, left, left),
  inset: (x: 8pt, y: 4pt),
  stroke: (x, y) => { if y <= 1 { (top: 0.5pt) } },
  fill: (x, y) => if y > 0 and calc.rem(y, 2) == 0 { rgb("#dfdfef") },
)
#show table.footer: set text(style: "italic")


= Introduction

An API@noauthor_api_2025 is a set of standardised rules that allow one piece of software to request and receive information or services from another piece of software. Much of the daily life - online shopping, banking, paying taxes - is built around simple standardised APIs. 

This note describes a simple API for interacting with microsimulation models. The initial intended use case for the API is embedding a tax benefit model into an online learning platform; possible other uses include  building 'mashups' of simulations from different providers, integrating realistic simulations into games, and running models from inside Content Management Systems (CMSs) such as WordPress. 

Standards have been developed for how such APIs should be designed@masse_rest_2011 and described@noauthor_swagger_2025, and the proposed API tries to adhere to these standards.

= Online Microsimulation Models

There have been online, publicly available versions of large Microsimulation models since the mid-1990s;
the Institute for Fiscal Studies' #link("https://web.archive.org/web/19970414074226/http://www.ifs.org.uk/DISCLAIM.HTM")[Be Your Own Chancellor]
(1995) and #link("https://virtual-worlds-research.com/demonstrations/virtual-economy/")[Virtual Economy]
(1999) were early examples. Contemporary examples include the #link("https://adrs-global.com/")[ADRS suite of South African simulations],
#link("")[TriplePC] and the University of Essex's #link("")[UK Mod].

These online models are implemented in different ways. TriplePC has the underlying simulation model and the web interface written in the same programming language (Julia@bezanson_julia:_2017), integrated into a single package. Older systems, and UKMod, have the public facing 'front end' written in a specialist languages like PHP@bakken_php_2000 or Java@arnold2005java, whilst the actual models are developed seperately and invoked as required by the front-end.

Microsimulation models have a number of common characteristics:

- they typically have a large number of inputs, outputs and other controls. It can take dozens of parameters to characterise, for example, an income tax system - tax rates, various allowances, switches for different options and so on;
- healthy models constantly evolve, as they are improved and as the world they try to capture changes. It's rarely a good sign when a model has the same inputs and outputs now as last year;
- they are typically (though not always) resource-intensitve and long running - from a few seconds up to hours or even days. (Even a few seconds is a long time for a typical API service);
- models typically go through a number of distinct phases - sitting in a job queue, initialising, running calculations, generating output, and so on.

Based on our experience since then ...

Object - run a model from something like Wordpress - without needing to have the model to hand.

= A typical Sequence

Session start - in the current implementation this is implicit in any request. In a fuller implementation this could include sending an api key, for example a JSON Web Token.



Submit - asyncronous possibly to a queueing program such as Torque

Monitor - 

= Features

RESTful (sort of). Reference O'Reilly.

Out of scope: security because ...

Learn about exact formats of inputs/outputs

Hacky session management: CORS shit append `session_id` on each response

Low marginal cost of adding a model (view) to a server

Typically front-ended by Apache/NGNX

Formats: JSON - optionally Markdown/XML/CSV

Describe parameters:

Validate at server end, even if also at client-side.

#link("")[Swagger].

= The API

Different for e.g. Julia Scotben, Python Landman so Julia one is:

#link(
  "https://microapi.virtual-worlds.scot",
)[https://microapi.virtual-worlds.scot]

Typical items:

```julia

    /model/params/set

    /model/settings/set

    /model/output/fetch/item
```

#link("https://microapi.virtual-worlds.scot/docs/")[Swagger Docs].

==

== Problems

buggy!


#figure(
  caption: [Others],
  placement: none,
  table(
    table.header[Benefit][Code Module][Notes],

    [Minimum Wages],
    [#link(
      "https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/HouseholdAdjuster.jl",
    )[HouseholdAdjuster.jl]],
    [ ],
  ),
)

#pagebreak()
