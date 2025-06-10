# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "chart.js/auto", to: "https://ga.jspm.io/npm:chart.js@4.4.0/auto/auto.js"

# ActionCable is loaded directly in the layout via CDN
