library(targets)

# Use tar_script() to create _targets.R and tar_edit()
# to open it again for editing.
# Then, run tar_make() to run the pipeline
# and tar_read(summary) to view the results.

# Set target-specific options such as packages.
tar_option_set(
  packages = c(
    "tidyverse",
    "gaussquad",
    "greta",
    "bayesplot",
    "testthat",
    "colorspace"
  )
)

# load all functions
. <- lapply(list.files("R", full.names = TRUE), source)

# End this file with a list of target objects.
list(

  # distributions over ratios of neut titres from Khoury et al, expressed as fold of convalescent
  tar_target(
    neut_ratios_vaccine,
    get_neut_ratios_vaccine()
  ),

  # VEs against different outcomes for products, doses at different times since vaccination.
  tar_target(
    ve_estimates,
    get_ve_estimates()
  ),

  # greta model of relationship between neuts and efficacies
  tar_target(
    neut_model_initial,
    build_neut_model(
      ve_estimates,
      neut_ratios_vaccine
    )
  ),

  # adding omicron parameters
  tar_target(
    neut_model,
    add_omicron_model(neut_model_initial)
  ),

  # fit model and check convergence
  tar_target(
    draws,
    fit(neut_model)
  ),

  tar_target(
    trace_plot,
    bayesplot::mcmc_trace(draws)
  ),

  tar_target(
    save_trace_plot,
    ggsave("figures/mcmc_trace.png",
       plot = trace_plot,
       width = 10,
       height = 7,
       bg = "white")
  ),

  # posterior samples of fitted VEs:
  tar_target(
    ve_fitted_sims,
    sim_fitted_ves(
      neut_model,
      draws
    )
  ),

  # plot of fit:
  tar_target(
    fit_plot,
    plot_ve_fit(
      neut_model$ve_data_modelling,
      ve_fitted_sims
    )
  ),

  tar_target(
    save_fit_plot,
    ggsave("figures/ve_fit.png",
       plot = fit_plot,
       width = 7,
       height = 7,
       bg = "white")
  ),

  # posterior predictive check on ECDF of observed VEs
  tar_target(
    ppc_plot,
    bayesplot::ppc_ecdf_overlay(
      neut_model$ve_data_modelling$ve,
      ve_fitted_sims)
  ),

  tar_target(
    save_ppc_plot,
    ggsave("figures/ecdf_ppc.png",
       plot = ppc_plot,
       width = 6,
       height = 5,
       bg = "white")
  ),

  # VEs against Delta over time
  tar_target(
    ve_predictions_delta,
    predict_ves(
      neut_model,
      draws,
      omicron_infection_multiplier = 4.4 # increase in neuts against D if infected by O
    )
  ),
  tar_target(
    save_ve_delta,
    write_csv(
      ve_predictions_delta,
      "outputs/ve_waning_predictions_delta.csv"
    )
  ),

  tar_target(
    waning_plot_delta,
    plot_waning(
      ve_predictions_delta
    ) +
    ggtitle("Predicted waning in vaccine effectiveness",
          "against the Delta variant")
  ),
  tar_target(
    save_waning_plot_delta,
    ggsave("figures/ve_waning_delta.png",
       plot = waning_plot_delta,
       width = 9,
       height = 6,
       bg = "white")
  ),

  tar_target(
    waning_plot_delta_data,
    plot_waning(
      ve_predictions_delta,
      neut_model$ve_data_modelling %>%
        filter(variant == "delta")
    ) +
    ggtitle("Predicted waning in vaccine effectiveness",
          "against the Delta variant")
  ),

  tar_target(
    save_waning_plot_delta_data,
    ggsave("figures/ve_waning_delta_with_data.png",
       plot = waning_plot_delta_data,
       width = 9,
       height = 6,
       bg = "white")
  ),

  # VE predictions for omicron
  tar_target(
    ve_predictions_omicron,
    predict_ves(
      neut_model,
      draws,
      omicron = TRUE,
      omicron_infection_multiplier = 14.4 # increase in neuts against Omicron if infected by Omicron
    )
  ),

  tar_target(
    ve_predictions_omicron_super_escape, # hypothetical can adjust as necessary
    predict_ves(
      neut_model,
      draws,
      omicron = TRUE,
      omicron_infection_multiplier = 14.4, # increase in newts against Omi if infected by Omi
      neut_immune_escape = 0.325
    )
  ),

  tar_target(
    save_ve_predictions_omicron,
    write_csv(
      ve_predictions_omicron_super_escape,
      "outputs/ve_waning_predictions_omicron_BA4.csv"
    )
  ),

  tar_target(
    waning_plot_omicron,
    plot_waning(
      ve_predictions_omicron,
      immunity_levels = c(
        "Omicron BA1/2 Infection",
        "Pfizer vaccine dose 2 + Omicron BA1/2 infection",
        "mRNA booster + Omicron BA1/2 infection",
        "mRNA booster",
        "Pfizer vaccine dose 2",
        "AZ vaccine dose 2",
        "mRNA dose 4",
        "mRNA dose 4 + Omicron BA1/2 infection")
      ) +
      ggtitle("Predicted waning in vaccine effectiveness",
              "against the Omicron BA1/2 subvariant")
  ),

  tar_target(
    save_waning_plot_omicron,
    ggsave("figures/ve_waning_omicron_BA12.png",
       plot = waning_plot_omicron,
       width = 9,
       height = 6,
       bg = "white")
  ),

  tar_target(
    omicron_ve_data,
    neut_model$ve_data_modelling %>%
      filter(
        variant == "omicron",
        dose > 1
      )
  ),

  tar_target(
    waning_plot_omicron_data,
    plot_waning(
      ve_predictions_omicron,
      omicron_ve_data,
      immunity_levels = c(
        "Omicron BA1/2 Infection",
        "Pfizer vaccine dose 2 + Omicron BA1/2 infection",
        "mRNA booster + Omicron BA1/2 infection",
        "mRNA booster",
        "Pfizer vaccine dose 2",
        "AZ vaccine dose 2")
    ) +
      ggtitle("Predicted waning in vaccine effectiveness",
              "against the Omicron variant")
  ),

  tar_target(
    save_waning_plot_omicron_data,
    ggsave("figures/ve_waning_omicron_with_data_BA12.png",
       plot = waning_plot_omicron_data,
       width = 9,
       height = 6,
       bg = "white")
  ),


  # posterior density of R0 and immune escape
  tar_target(
    omicron_params,
    sim_omicron_params(
      neut_model,
      draws
    )
  ),

  tar_target(
    omicron_params_plot,
    plot_omicron_params(omicron_params) +
      coord_cartesian(
        xlim = c(0, 0.7),
        ylim = c(0.5, 1.4)
      )
  ),

  tar_target(
    save_omicron_params_plot,
    ggsave("figures/omicron_params.png",
           plot = omicron_params_plot,
           width = 7,
           height = 7,
           bg = "white")
  ),

  tar_target(
    omicron_params_plot_100pc,
    plot_omicron_params(omicron_params) +
      coord_cartesian(
        xlim = c(0, 1),
        ylim = c(0.5, 1.4)
      )
  ),

  tar_target(
    save_omicron_params_plot_100pc,
    ggsave("figures/omicron_params_100pc.png",
           plot = omicron_params_plot_100pc,
           width = 7,
           height = 7,
           bg = "white")
  ),

  tar_target(
    omicron_params_plot_lines,
    plot_omicron_params(
      omicron_params,
      neut_fold_lines = c(3, 5, 10, 15)
    )
  ),

  tar_target(
    save_omicron_params_plot_lines,
    ggsave("figures/omicron_params_with_lines.png",
       plot = omicron_params_plot_lines,
       width = 7,
       height = 7,
       bg = "white")
  ),

  tar_target(
    omicron_neut_fold_plot,
    plot_omicron_neut_fold(omicron_params)
  ),

  tar_target(
    save_omicron_neut_fold_plot,
    ggsave("figures/omicron_neut_fold.png",
       plot = omicron_neut_fold_plot,
       width = 7,
       height = 7,
       bg = "white")
  ),

  # given point estimates on avocado, compute VEs:
  tar_target(
    omicron_scenarios,
    tibble::tribble(
      ~scenario, ~R0_ratio_target, ~immune_evasion_target,
      "pessimistic", 1.1, 0.5,
      "intermediate", 0.85, 0.3,
      "optimistic", 0.6, 0.1
    )
  ),

  tar_target(
    omicron_params_plot_points,
    omicron_params_plot +
      geom_point(
        aes(
          x = immune_evasion_target,
          y = R0_ratio_target
        ),
        data = omicron_scenarios
      ) +
      geom_text(
        aes(
          x = immune_evasion_target,
          y = R0_ratio_target,
          label = scenario
        ),
        data = omicron_scenarios,
        vjust = 0,
        nudge_y = 0.02
      )
  ),

  tar_target(
    save_omicron_params_plot_points,
    ggsave("figures/omicron_params_with_points.png",
       plot = omicron_params_plot_points,
       width = 7,
       height = 7,
       bg = "white")
  ),

  tar_target(
    scenario_parameters,
    format_scenario_parameters(
      neut_model = neut_model,
      draws = draws,
      scenarios = omicron_scenarios
    )
  ),

  tar_target(
    save_scenario_parameters,
    write_csv(
      scenario_parameters,
      "outputs/scenario_parameters_omicron.csv"
    )
  ),

  tar_target(
    omicron_params_plot_za_120d,
    sim_omicron_params(
      neut_model,
      draws,
      baseline_immunity = "za",
      days_waning = 120
    ) %>%
    plot_omicron_params(
      neut_fold_lines = c(3, 5, 10, 15)
    )
  ),

  tar_target(
    save_omicron_params_plot_za_120d,
    ggsave("figures/omicron_params_za_120d.png",
       plot = omicron_params_plot_za_120d,
       width = 7,
       height = 7,
       bg = "white")
  )

)
