using Genie.Router
using SwagUI
using SwaggerMarkdown

import MicrosimAPIv1
import .ScotbenAPIImpl

route("/") do
  serve_static_file("welcome.html")
end


@swagger"""
/model/model/:model/edition/:edition/user/:user/params/list-available:
  get:
    description: List all the avaliable default parameter systems (for example fy2023, Scotland)
    responses:
      '200':
        description: A json list of parameter systems.
"""
route( "/model/:model/edition/:edition/user/:user/params/list-available", MicrosimAPIv1.ScotbenAPIImpl.params_list_available, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/params/initialise:
  post:
    description: Reset parameters to the default.
    responses:
      '200':
        description: A json list of default parameters.
"""
route( "/model/:model/edition/:edition/user/:user/params/initialise", MicrosimAPIv1.ScotbenAPIImpl.params_initialise, method = POST  )

@swagger"""
/model/:model/edition/:edition/user/:user/params/get:
  post:
    description: Get the current parameters.
    responses:
      '200':
        description: A json list of current parameters.
"""
route( "/model/:model/edition/:edition/user/:user/params/get", MicrosimAPIv1.ScotbenAPIImpl.params_get, method = POST  )

@swagger"""
/model/:model/edition/:edition/user/:user/params/set:
  post:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/params/set", MicrosimAPIv1.ScotbenAPIImpl.params_set, method = POST  )

@swagger"""
/model/:model/edition/:edition/user/:user/params/helppage:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/params/helppage", MicrosimAPIv1.ScotbenAPIImpl.params_helppage, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/params/set:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/params/set", MicrosimAPIv1.ScotbenAPIImpl.params_set, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/params/validate:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/params/validate", MicrosimAPIv1.ScotbenAPIImpl.params_validate, method = POST  )

@swagger"""
/model/:model/edition/:edition/user/:user/params/describe:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/params/describe", MicrosimAPIv1.ScotbenAPIImpl.params_describe, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/params/subsys:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/params/subsys", MicrosimAPIv1.ScotbenAPIImpl.params_subsys, method = GET)


@swagger"""
/model/:model/edition/:edition/user/:user/params/labels:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/params/labels", MicrosimAPIv1.ScotbenAPIImpl.params_labels, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/settings/initialise:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/settings/initialise", MicrosimAPIv1.ScotbenAPIImpl.settings_initialise, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/settings/set:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/settings/set", MicrosimAPIv1.ScotbenAPIImpl.settings_set, method = POST  )

@swagger"""
/model/:model/edition/:edition/user/:user/settings/validate:
  get:
    description: set model parameters to the payload.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/settings/validate", MicrosimAPIv1.ScotbenAPIImpl.settings_validate, method = POST  )

@swagger"""
/model/:model/edition/:edition/user/:user/settings/describe:
  get:
    description: a dict of key/description for each setting variable.
    responses:
      '200':
        description:  a dict of key/description for each setting variable.
"""
route( "/model/:model/edition/:edition/user/:user/settings/describe", MicrosimAPIv1.ScotbenAPIImpl.settings_describe, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/settings/helppage:
  get:
    description: A help page (probably in markdown) for the run settings.
    responses:
      '200':
        description: A help page (probably in markdown) for the run settings.
"""
route( "/model/:model/edition/:edition/user/:user/settings/helppage", MicrosimAPIv1.ScotbenAPIImpl.settings_helppage, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/settings/labels:
  get:
    description: Key/value dict of labels for each settings option.
    responses:
      '200':
        description: Key/value dict of labels for each settings option.
"""
route( "/model/:model/edition/:edition/user/:user/settings/labels", MicrosimAPIv1.ScotbenAPIImpl.settings_labels, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/run/status:
  get:
    description: The status of the current run, if any.
    responses:
      '200':
        description: A json dict with one of the keys from `/model/:model/edition/:edition/user/:user/run/statuses` and optional counts.
"""
route( "/model/:model/edition/:edition/user/:user/run/status", MicrosimAPIv1.ScotbenAPIImpl.run_status, method = GET )

@swagger"""
/model/:model/edition/:edition/user/:user/run/statuses:
  get:
    description: an ordered dict of key/label values for possible run statuses (queued/executing/output, etc.) Should also describle any additional info e.g. counts of units processed, position in job queue, etc..
    responses:
      '200':
        description: an ordered dict of key/label values for possible run statuses (queued/executing/output, etc.)..
"""
route( "/model/:model/edition/:edition/user/:user/run/statuses", MicrosimAPIv1.ScotbenAPIImpl.run_statuses, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/run/submit:
  post:
    description: submit a run with the current params and settings.
    responses:
      '200':
        description: xxx.
"""
route( "/model/:model/edition/:edition/user/:user/run/submit", MicrosimAPIv1.ScotbenAPIImpl.run_submit, method = POST )

@swagger"""
/model/:model/edition/:edition/user/:user/run/abort:
  get:
    description: abort the run associated with the session
    responses:
      '200':
        description: if aborted OK.
"""
route( "/model/:model/edition/:edition/user/:user/run/abort", MicrosimAPIv1.ScotbenAPIImpl.run_abort, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/output/items:
  get:
    description: A name/description dict of items created by a run, in json.
    responses:
      '200':
        description: A name/description dict of items created by a run, in json.
"""
route( "/model/:model/edition/:edition/user/:user/output/items", MicrosimAPIv1.ScotbenAPIImpl.output_items, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/output/phunpa:
  get:
    description: All or most outputs from a run as a zip file.
    responses:
      '200':
        description: downloadable zipfile.
"""
route( "/model/:model/edition/:edition/user/:user/output/phunpak", MicrosimAPIv1.ScotbenAPIImpl.output_phunpak, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/output/labels:
  get:
    description: Return a dict of key/value labels for all output items.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/output/labels", MicrosimAPIv1.ScotbenAPIImpl.output_labels, method = GET  )

@swagger"""
/model/:model/edition/:edition/user/:user/output/fetch/:format/:item/:subitem:
  get:
    description: return an output item `item` and optionally `subitem`. Should be in the list of outputs from `/model/:model/edition/:edition/user/:user/settings/helppage`. Probably in json. Format is one of 'json', 'html', 'svg'
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/model/:model/edition/:edition/user/:user/output/fetch/:format/:item", MicrosimAPIv1.ScotbenAPIImpl.output_fetch_item, method = GET  )
route( "/model/:model/edition/:edition/user/:user/output/fetch/:format/:item/:subitem", MicrosimAPIv1.ScotbenAPIImpl.output_fetch_item, method = GET  )
route( "/model/:model/edition/:edition/user/:user/output/fetch/:format/:item/:subitem/:sub2", MicrosimAPIv1.ScotbenAPIImpl.output_fetch_item, method = GET  )

@swagger"""
/get_session_id:
  get:
    description: Get the id for the current session or create one if no current session.
    responses:
      '200':
        description: id of session
"""
route( "/get_session_id", MicrosimAPIv1.ScotbenAPIImpl.get_session_id, method=GET )

@swagger"""
/destroy_session:
  get:
    description: destroy!
    responses:
      '200':
        description: the old id and 'result=0' if OK.
"""
route( "/destroy_session", MicrosimAPIv1.ScotbenAPIImpl.destroy_session, method=GET )

@swagger"""
/model/:model/edition/:edition/user/:user/settings/helppage:
  get:
    description: Get the id for the current session or create one if no current session.
    responses:
      '200':
        description: A json list of new parameters.
"""
route( "/get_session_id", MicrosimAPIv1.ScotbenAPIImpl.get_session_id, method=GET )

route("/docs") do 
    info = Dict{String, Any}()
    info["title"] = "Microsim API"
    info["version"] = "0.1"
    openApi = OpenAPI("2.0", info)
    swagger_document = build(openApi)
    render_swagger(swagger_document)
end
