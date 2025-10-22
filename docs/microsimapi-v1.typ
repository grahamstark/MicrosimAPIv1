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
      email: "graham.stark@northumbria.ac.uk"
    ),
  ),
  paper-size: "a4",
  index-terms: ("Microsimulation","APIs"),
  bibliography: bibliography("PHd.bib"),
  figure-supplement: [Fig.],
)

#show link: underline
  
#show table.cell.where(x: 2): set text(style: "italic", size:7pt)
#show table.cell.where(x: 1): set text(size: 4pt, font:"JuliaMono")
#show table.cell.where(x: 0): set text(size: 7pt)

#set table(
    columns: (8em, auto, auto),
    align: (left, left, left),
    inset: (x: 8pt, y: 4pt),
    stroke: (x, y) => {if y <= 1 { (top: 0.5pt) }},
    fill: (x, y) => if y > 0 and calc.rem(y, 2) == 0  { rgb("#dfdfef") },
  )
#show table.footer: set text(style: "italic")


= Introduction

This note describes 

= Purpose

There have been online, publicly available versions of large Microsimulation models since the mid-1990s; 
the Institute for Fiscal Studies' #link("https://web.archive.org/web/19970414074226/http://www.ifs.org.uk/DISCLAIM.HTM")[Be Your Own Chancellor] 
(1995) and #link("https://virtual-worlds-research.com/demonstrations/virtual-economy/")[Virtual Economy] 
(1999) were early examples. Contemporary examples include the #link("https://adrs-global.com/")[ADRS suite of South African simulations],
#link("")[TriplePC] and the University of Essex's #link("")[UK Mod].

All these models are implemented very differently. ...

Our experience of building such models suggests to us that there would be advantages in having a standardised method
of interacting..

Based on our experience since then ...

Object - run a model from something like Wordpress - without needing to have the model to hand.

= Characteristics of Microsimulation Models

Long running 

Very different implementations

Phases (queues, running)

Different inputs and outputs

Parameters vs Settings



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

#link("https://microapi.virtual-worlds.scot")[https://microapi.virtual-worlds.scot]

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

    [Minimum Wages],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/HouseholdAdjuster.jl")[HouseholdAdjuster.jl]],[ ],
      )
)

#pagebreak()