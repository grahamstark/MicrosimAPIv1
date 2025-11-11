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

= Flow Of The API

This is how the test implementation works currently.

1. (Possibly, and not yet implemented) Client queries the server: available memory, jobs running, jobs queued, etc.

2. Client starts a session (this may be implied when e.g. the client sends some parameters, or explicit). Possibly an API token is provided. Server side, defautlt parameters and outputs are created and assigned to the session.

Note: parameters can be divided into policy parameters (e.g. tax rates) and run settings (e.g. numbers of households to run over).These are treated as seperate records;

3. Optionally, client queries the server for the required structure of inputs and outputs. The response might be in JSON, XML etc. and includes names of parameters, minima and maxima, preferred formats, etc. Possibly the client builds a UI automatically from this information (I have a rough version of this). Alternatively, the client might have a pre-built UI, as in the Scotben demo. Server site, these replies might simply be some static files;

4. Client gets inputs, probably from a web form, packages them in the format required by (3) and sends them to the server. This may happen serveral times. Server side, the parameters are validated and either an error message is sent back or the session parameters are updated.

5. The client runs the model. Server side:
 - a run data structure is created for monitoring and holding output in a server dictionary. This is keyed by a hash of the parameter values - if the key already exists, we send back stored results instantly. The run id is added to the session information for the user;
 - if no instant reply, the set of parameters is placed in a job queue. Jobs are pulled out of the queue by model run workers.

 Doing it this way allows the server to respond instantly to the run submission. In the test implementation the job queue is simply an Channel structure on the server, but bigger implementations might use proper queue software like Torque (I've used this before)

6. The server monitors the job. In the test implementation, we use an observer/observable pattern to write a short record to the run dictionary every time some event happens (additional 1,000 households processed, output creation phase reached etc.). Client side, a progress bar is drawn by repeatedly querying the server for run progress.

7. When the phase of the run is 'complete', the client begins making requests for output. In the test implementation, all the output is in json which is parsed into tables and graphs client-side. (The library for this is already huge).

8. Optionally, the session is destroyed.




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
