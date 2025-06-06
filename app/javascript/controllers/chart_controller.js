import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chart"
export default class extends Controller {
  static targets = ["canvas"]
  
  connect() {
    if (this.hasCanvasTarget) {
      this.initializeChart()
    }
  }
  
  async initializeChart() {
    // Dynamically import Chart.js to ensure it's loaded properly
    const { Chart } = await import('chart.js/auto')
    
    const ctx = this.canvasTarget.getContext('2d')
    
    // Sample data - this would come from your backend in a real implementation
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    const data = [25, 40, 30, 50, 60, 45, 75, 70, 85, 60, 75, 90]
    
    // Create the chart
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Number of Reviews',
          data: data,
          backgroundColor: 'rgba(59, 130, 246, 0.2)',
          borderColor: 'rgba(59, 130, 246, 1)',
          borderWidth: 2,
          tension: 0.3,
          pointBackgroundColor: 'rgba(59, 130, 246, 1)',
          pointBorderColor: '#fff',
          pointBorderWidth: 1,
          pointRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Number of Reviews'
            }
          },
          x: {
            title: {
              display: true,
              text: 'Month'
            }
          }
        },
        plugins: {
          legend: {
            display: true,
            position: 'top'
          },
          tooltip: {
            mode: 'index',
            intersect: false
          }
        }
      }
    })
  }
  
  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }
}
