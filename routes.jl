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
  post:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/params/set", MSA.scotben_params_set, method = POST  )

@swagger"""
/scotben/params/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/params/helppage", MSA.scotben_params_helppage, method = GET  )

@swagger"""
/scotben/params/set:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/params/set", MSA.scotben_params_set, method = GET  )

@swagger"""
/scotben/params/validate:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/params/validate", MSA.scotben_params_validate, method = POST  )

@swagger"""
/scotben/params/describe:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/params/describe", MSA.scotben_params_describe, method = GET  )

@swagger"""
/scotben/params/subsys:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/params/subsys", MSA.scotben_params_subsys, method = GET)


@swagger"""
/scotben/params/labels:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/params/labels", MSA.scotben_params_labels, method = GET  )

@swagger"""
/scotben/settings/initialise:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/settings/initialise", MSA.scotben_settings_initialise, method = GET  )

@swagger"""
/scotben/settings/set:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/settings/set", MSA.scotben_settings_set, method = POST  )

@swagger"""
/scotben/settings/validate:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/settings/validate", MSA.scotben_settings_validate, method = POST  )

@swagger"""
/scotben/settings/describe:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/settings/describe", MSA.scotben_settings_describe, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/settings/helppage", MSA.scotben_settings_helppage, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/settings/labels", MSA.scotben_settings_labels, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/run/status", MSA.scotben_run_status, method = GET )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/run/statuses", MSA.scotben_run_statuses, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/run/submit", MSA.scotben_run_submit, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/run/abort", MSA.scotben_run_abort, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/output/items", MSA.scotben_output_items, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/output/phunpak", MSA.scotben_output_phunpak, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/output/labels", MSA.scotben_output_labels, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/output/fetch/:item/:subitem", MSA.scotben_output_fetch_item, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/get_session_id", MSA.get_session_id, method=GET )

route("/docs") do 
    info = Dict{String, Any}()
    info["title"] = "Microsim API"
    info["version"] = "0.1"
    openApi = OpenAPI("2.0", info)
    swagger_document = build(openApi)
    render_swagger(swagger_document)
end
