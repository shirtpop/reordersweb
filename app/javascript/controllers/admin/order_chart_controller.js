import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chart"]
  static values = {
    data: Object,
    range: { type: Number, default: 30 }
  }

  connect() {
    // Dynamically load ApexCharts script if not already loaded
    if (typeof window.ApexCharts === 'undefined') {
      this.loadScript('https://cdn.jsdelivr.net/npm/apexcharts@3.46.0/dist/apexcharts.min.js')
        .then(() => this.renderChart())
    } else {
      this.renderChart()
    }

    // Set initial active button state
    this.updateButtonStates(this.rangeValue)
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  loadScript(src) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = src
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  changeRange(event) {
    const newRange = parseInt(event.currentTarget.dataset.range)
    this.rangeValue = newRange
    this.updateButtonStates(newRange)
    this.fetchAndUpdateChart(newRange)
  }

  updateButtonStates(activeRange) {
    // Find all range buttons
    const buttons = this.element.querySelectorAll('[data-action*="changeRange"]')
    buttons.forEach(button => {
      const range = parseInt(button.dataset.range)
      if (range === activeRange) {
        // Active state
        button.className = "px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors text-white bg-blue-600 border-blue-600 dark:bg-blue-500 dark:border-blue-500"
      } else {
        // Inactive state
        button.className = "px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors text-gray-700 bg-white border-gray-300 hover:bg-gray-50 dark:text-gray-300 dark:bg-gray-700 dark:border-gray-600 dark:hover:bg-gray-600"
      }
    })
  }

  fetchAndUpdateChart(days) {
    // Fetch new data from the server
    const url = `/admin/dashboard/chart_data?days=${days}`

    fetch(url, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      this.updateChart(data)
    })
    .catch(error => {
      console.error('Error fetching chart data:', error)
    })
  }

  updateChart(data) {
    if (this.chart) {
      this.chart.updateOptions({
        xaxis: {
          categories: Object.keys(data)
        }
      })
      this.chart.updateSeries([{
        name: 'Orders',
        data: Object.values(data)
      }])
    }
  }

  renderChart() {
    const isDark = document.documentElement.classList.contains('dark')

    const options = {
      chart: {
        type: 'area',
        height: 300,
        fontFamily: 'Inter, sans-serif',
        toolbar: {
          show: false
        },
        zoom: {
          enabled: false
        },
        background: 'transparent'
      },
      series: [{
        name: 'Orders',
        data: Object.values(this.dataValue)
      }],
      xaxis: {
        categories: Object.keys(this.dataValue),
        labels: {
          style: {
            colors: isDark ? '#9CA3AF' : '#6B7280',
            fontSize: '12px'
          },
          formatter: function(value) {
            // Format date as "Jan 15"
            const date = new Date(value)
            return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
          }
        },
        axisBorder: {
          show: false
        },
        axisTicks: {
          show: false
        }
      },
      yaxis: {
        labels: {
          style: {
            colors: isDark ? '#9CA3AF' : '#6B7280',
            fontSize: '12px'
          },
          formatter: function(value) {
            return Math.floor(value)
          }
        }
      },
      grid: {
        borderColor: isDark ? '#374151' : '#E5E7EB',
        strokeDashArray: 4,
        padding: {
          left: 10,
          right: 10,
          top: -20
        }
      },
      fill: {
        type: 'gradient',
        gradient: {
          opacityFrom: 0.55,
          opacityTo: 0,
          shade: '#1C64F2',
          gradientToColors: ['#1C64F2']
        }
      },
      dataLabels: {
        enabled: false
      },
      stroke: {
        width: 3,
        curve: 'smooth',
        colors: ['#1C64F2']
      },
      tooltip: {
        enabled: true,
        theme: isDark ? 'dark' : 'light',
        style: {
          fontSize: '14px',
          fontFamily: 'Inter, sans-serif'
        },
        y: {
          formatter: function(value) {
            return value + ' orders'
          }
        }
      },
      legend: {
        show: false
      },
      colors: ['#1C64F2']
    }

    this.chart = new window.ApexCharts(this.chartTarget, options)
    this.chart.render()
  }
}
