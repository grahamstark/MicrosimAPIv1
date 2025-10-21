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
  post:
    description: Reset parameters to the default.
    responses:
      '200':
        description: A json list of default parameters.
"""
route( "/scotben/params/initialise", MSA.scotben_params_initialise, method = POST  )

@swagger"""
/scotben/params/get:
  post:
    description: Get the current parameters.
    responses:
      '200':
        description: A json list of current parameters.
"""
route( "/scotben/params/get", MSA.scotben_params_get, method = POST  )

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
    description: a dict of key/description for each setting variable.
    responses:
      '200':
        description:  a dict of key/description for each setting variable.
"""
route( "/scotben/settings/describe", MSA.scotben_settings_describe, method = GET  )

@swagger"""
/scotben/settings/helppage:
  get:
    description: A help page (probably in markdown) for the run settings.
    responses:
      '200':
        description: A help page (probably in markdown) for the run settings.
"""
route( "/scotben/settings/helppage", MSA.scotben_settings_helppage, method = GET  )

@swagger"""
/scotben/settings/labels:
  get:
    description: Key/value dict of labels for each settings option.
    responses:
      '200':
        description: Key/value dict of labels for each settings option.
"""
route( "/scotben/settings/labels", MSA.scotben_settings_labels, method = GET  )

@swagger"""
/scotben/run/status:
  get:
    description: The status of the current run, if any.
    responses:
      '200':
        description: A json dict with one of the keys from `/scotben/run/statuses` and optional counts.
"""
route( "/scotben/run/status", MSA.scotben_run_status, method = GET )

@swagger"""
/scotben/run/statuses:
  get:
    description: an ordered dict of key/label values for possible run statuses (queued/executing/output, etc.) Should also describle any additional info e.g. counts of units processed, position in job queue, etc..
    responses:
      '200':
        description: an ordered dict of key/label values for possible run statuses (queued/executing/output, etc.)..
"""
route( "/scotben/run/statuses", MSA.scotben_run_statuses, method = GET  )

@swagger"""
/scotben/run/submit:
  post:
    description: submit a run with the current params and settings.
    responses:
      '200':
        description: xxx.
"""
route( "/scotben/run/submit", MSA.scotben_run_submit, method = POST )

@swagger"""
/scotben/run/abort:
  get:
    description: abort the run associated with the session
    responses:
      '200':
        description: if aborted OK.
"""
route( "/scotben/run/abort", MSA.scotben_run_abort, method = GET  )

@swagger"""
/scotben/output/items:
  get:
    description: A name/description dict of items created by a run, in json.
    responses:
      '200':
        description: A name/description dict of items created by a run, in json.
"""
route( "/scotben/output/items", MSA.scotben_output_items, method = GET  )

@swagger"""
/scotben/output/phunpa:
  get:
    description: All or most outputs from a run as a zip file.
    responses:
      '200':
        description: downloadable zipfile.
"""
route( "/scotben/output/phunpak", MSA.scotben_output_phunpak, method = GET  )

@swagger"""
/scotben/output/labels:
  get:
    description: Return a dict of key/value labels for all output items.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/output/labels", MSA.scotben_output_labels, method = GET  )

@swagger"""
/scotben/output/fetch/:item/:subitem:
  get:
    description: return an output item `item` and optionally `subitem`. Should be in the list of outputs from `/scotben/settings/helppage`. Probably in json.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/scotben/output/fetch/:item/:subitem", MSA.scotben_output_fetch_item, method = GET  )

@swagger"""
/get_session_id:
  get:
    description: Get the id for the current session or create one if no current session.
    responses:
      '200':
        description: id of session
"""
route( "/get_session_id", MSA.get_session_id, method=GET )

@swagger"""
/destroy_session:
  get:
    description: destroy!
    responses:
      '200':
        description: the old id and 'result=0' if OK.
"""
route( "/destroy_session", MSA.destroy_session, method=GET )

@swagger"""
/scotben/settings/helppage:
  get:
    description: Get the id for the current session or create one if no current session.
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
