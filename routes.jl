using Genie.Router
using SwagUI
using SwaggerMarkdown

import MicrosimAPIv1 as MSA

route("/") do
  serve_static_file("welcome.html")
end

@swagger"""
/scotben/params/list-available:
  get:
    description: List all the avaliable default parameter systems (for example fy2023, Scotland)
    responses:
      '200':
        description: A json list of parameter systems.
"""
route( "/scotben/params/list-available", MSA.scotben_params_list_available, method = GET  )

@swagger"""
/scotben/params/initialise:
  get:
    description: Reset parameters to the default.
    responses:
      '200':
        description: A json list of default parameters.
"""
route( "/scotben/params/initialise", MSA.scotben_params_initialise, method = GET  )

@swagger"""
/scotben/params/set:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/params/set", MSA.scotben_params_set, method = POST  )



@swagger"""
/scotben/params/validate:
  get:
    description: validate the parameter set. Parameters are the same as returned by `initialise`. Params are checked for range only atm, plus arrays checked for ascending order.
    parameters: 
      - in: query
        name: params
        required: true
        description: Parameter set as JSON, in the format returned by `initialise` above.
    responses:
      '200':
        description: if a dictionary of errors, keyed by parameter names
      '500':
        description: if the params can't be parsed at all.
"""
route( "/scotben/params/validate", MSA.scotben_params_validate, method = POST  )


@swagger"""
/scotben/params/describe:
  get:
    description: validate the parameter set. Parameters are the same as returned by `initialise`. Params are checked for range only atm, plus arrays checked for ascending order
     responses:
      '200':
        description: a document with acceptable ranges, labels, etc. for the parameters
"""
route( "/scotben/params/describe", MSA.scotben_params_describe, method = GET  )

@swagger"""
/scotben/params/subsys:
  get:
    description: Optional: if the parameters have multiple sub-records, select a particular subset to default to.
     responses:
      '200':
        description: key for the subset
"""
route( "/scotben/params/subsys", MSA.scotben_params_subsys, method = GET)


@swagger"""
/scotben/params/helppage:
  get:
    description: return a text document with help information.
     responses:
      '200':
        description: a text document with help information.
"""
route( "/scotben/params/helppage", MSA.scotben_params_helppage, method = GET  )

route( "/scotben/params/labels", MSA.scotben_params_labels, method = GET  )

route( "/scotben/settings/initialise", MSA.scotben_settings_initialise, method = GET  )
route( "/scotben/settings/set", MSA.scotben_settings_set, method = POST  )
route( "/scotben/settings/validate", MSA.scotben_settings_validate, method = POST  )
route( "/scotben/settings/describe", MSA.scotben_settings_describe, method = GET  )
route( "/scotben/settings/helppage", MSA.scotben_settings_helppage, method = GET  )
route( "/scotben/settings/labels", MSA.scotben_settings_labels, method = GET  )

route( "/scotben/run/status", MSA.scotben_run_status, method = GET )
route( "/scotben/run/statuses", MSA.scotben_run_statuses, method = GET  )
route( "/scotben/run/submit", MSA.scotben_run_submit, method = GET  )
route( "/scotben/run/abort", MSA.scotben_run_abort, method = GET  )

route( "/scotben/output/items", MSA.scotben_output_items, method = GET  )
route( "/scotben/output/phunpak", MSA.scotben_output_phunpak, method = GET  )
route( "/scotben/output/labels", MSA.scotben_output_labels, method = GET  )
route( "/scotben/output/fetch/:item/:subitem", MSA.scotben_output_fetch_item, method = GET  )

route("/docs") do 
  # FIXME this is broken.
  # build a swagger document from markdown
  info = Dict{String, Any}()
  info["title"] = "Microsim API"
  info["version"] = "1.0"
  openApi = OpenAPI("2.0", info)
  swagger_document = build(openApi)
  render_swagger(swagger_document)
end
