using Genie.Router
import MicrosimAPIv1 as MSA

route("/") do
  serve_static_file("welcome.html")
end

route( "/scotben/params/list-available", MSA.scotben_params_list_available, method = POST  )
route( "/scotben/params/initialise", MSA.scotben_params_initialise, method = POST  )
route( "/scotben/params/set", MSA.scotben_params_set, method = POST  )
route( "/scotben/params/validate", MSA.scotben_params_validate, method = POST  )
route( "/scotben/params/describe", MSA.scotben_params_describe, method = POST  )
route( "/scotben/params/subsys", MSA.scotben_params_subsys, method = POST  )
route( "/scotben/params/helppage", MSA.scotben_params_helppage, method = POST  )
route( "/scotben/params/labels", MSA.scotben_params_labels, method = POST  )

route( "/scotben/settings/initialise", MSA.scotben_settings_initialise, method = POST  )
route( "/scotben/settings/set", MSA.scotben_settings_set, method = POST  )
route( "/scotben/settings/validate", MSA.scotben_settings_validate, method = POST  )
route( "/scotben/settings/describe", MSA.scotben_settings_describe, method = POST  )
route( "/scotben/settings/helppage", MSA.scotben_settings_helppage, method = POST  )
route( "/scotben/settings/labels", MSA.scotben_settings_labels, method = POST  )

route( "/scotben/run/status", MSA.scotben_run_status, method = POST  )
route( "/scotben/run/statuses", MSA.scotben_run_statuses, method = POST  )
route( "/scotben/run/submit", MSA.scotben_run_submit, method = POST  )
route( "/scotben/run/abort", MSA.scotben_run_abort, method = POST  )

route( "/scotben/output/items", MSA.scotben_output_items, method = POST  )
route( "/scotben/output/phunpak", MSA.scotben_output_phunpak, method = POST  )
route( "/scotben/output/labels", MSA.scotben_output_labels, method = POST  )
route( "/scotben/output/fetch/:item/:subitem", MSA.scotben_output_fetch_item, method = POST  )

route( "/scotben/params/list-available", MSA.scotben_params_list_available, method = GET  )
route( "/scotben/params/initialise", MSA.scotben_params_initialise, method = GET  )
route( "/scotben/params/set", MSA.scotben_params_set, method = GET  )
route( "/scotben/params/validate", MSA.scotben_params_validate, method = GET  )
route( "/scotben/params/describe", MSA.scotben_params_describe, method = GET  )
route( "/scotben/params/subsys", MSA.scotben_params_subsys, method = GET  )
route( "/scotben/params/helppage", MSA.scotben_params_helppage, method = GET  )
route( "/scotben/params/labels", MSA.scotben_params_labels, method = GET  )

route( "/scotben/settings/initialise", MSA.scotben_settings_initialise, method = GET  )
route( "/scotben/settings/set", MSA.scotben_settings_set, method = GET  )
route( "/scotben/settings/validate", MSA.scotben_settings_validate, method = GET  )
route( "/scotben/settings/describe", MSA.scotben_settings_describe, method = GET  )
route( "/scotben/settings/helppage", MSA.scotben_settings_helppage, method = GET  )
route( "/scotben/settings/labels", MSA.scotben_settings_labels, method = GET  )

route( "/scotben/run/status", MSA.scotben_run_status, method = GET  )
route( "/scotben/run/statuses", MSA.scotben_run_statuses, method = GET  )
route( "/scotben/run/submit", MSA.scotben_run_submit, method = GET  )
route( "/scotben/run/abort", MSA.scotben_run_abort, method = GET  )

route( "/scotben/output/items", MSA.scotben_output_items, method = GET  )
route( "/scotben/output/phunpak", MSA.scotben_output_phunpak, method = GET  )
route( "/scotben/output/labels", MSA.scotben_output_labels, method = GET  )
route( "/scotben/output/fetch/:item/:subitem", MSA.scotben_output_fetch_item, method = GET  )