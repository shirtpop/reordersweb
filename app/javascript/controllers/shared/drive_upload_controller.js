import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",
    "fileInput", 
    "progressContainer",
    "progressBar",
    "progressText",
    "errorContainer",
    "errorMessage",
    "imagesContainer",
    "imageCard"
  ]

  static values = {
    attachableType: String,
    attachableId: String
  }

  connect() {
    this.setupDragAndDrop()
    this.setupTurboStreamListener()
  }

  setupTurboStreamListener() {
    // Listen for Turbo Stream renders to hide progress when upload is complete
    document.addEventListener('turbo:before-stream-render', (event) => {
      // Check if the stream contains our images container
      if (event.detail.newStream?.includes(`images_container_${this.attachableTypeValue.toLowerCase()}_${this.attachableIdValue}`)) {
        this.hideProgress()
        this.resetFileInput()
      }
    })
  }

  setupDragAndDrop() {
    const dropZone = this.element
    
    dropZone.addEventListener('dragover', this.handleDragOver.bind(this))
    dropZone.addEventListener('dragenter', this.handleDragEnter.bind(this))
    dropZone.addEventListener('dragleave', this.handleDragLeave.bind(this))
    dropZone.addEventListener('drop', this.handleDrop.bind(this))
  }

  handleDragOver(event) {
    event.preventDefault()
    this.element.classList.add('border-blue-500', 'bg-blue-50', 'dark:bg-blue-900/20')
  }

  handleDragEnter(event) {
    event.preventDefault()
    this.element.classList.add('border-blue-500', 'bg-blue-50', 'dark:bg-blue-900/20')
  }

  handleDragLeave(event) {
    event.preventDefault()
    // Only remove classes if we're leaving the drop zone entirely
    if (!this.element.contains(event.relatedTarget)) {
      this.element.classList.remove('border-blue-500', 'bg-blue-50', 'dark:bg-blue-900/20')
    }
  }

  handleDrop(event) {
    event.preventDefault()
    this.element.classList.remove('border-blue-500', 'bg-blue-50', 'dark:bg-blue-900/20')
    
    const files = Array.from(event.dataTransfer.files)
    this.uploadFiles(files)
  }

  triggerFileInput() {
    this.fileInputTarget.click()
  }

  handleFiles(event) {
    const files = Array.from(event.target.files)
    this.uploadFiles(files)
  }

  uploadFiles(files) {
    // Validate files
    const validFiles = this.validateFiles(files)
    if (validFiles.length === 0) return

    this.hideError()
    this.showProgress()
    
    // Upload files one by one or all at once
    this.uploadMultipleFiles(validFiles)
  }

  validateFiles(files) {
    const validFiles = []
    const maxSize = 10 * 1024 * 1024 // 10MB
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif']
    
    for (const file of files) {
      if (!allowedTypes.includes(file.type)) {
        this.showError(`${file.name} is not a valid image type. Please use PNG, JPG, or GIF.`)
        continue
      }
      
      if (file.size > maxSize) {
        this.showError(`${file.name} is too large. Maximum size is 10MB.`)
        continue
      }
      
      validFiles.push(file)
    }
    
    return validFiles
  }

  async uploadMultipleFiles(files) {
    const totalFiles = files.length
    let completedFiles = 0
    
    try {
      for (const file of files) {
        await this.uploadSingleFile(file)
        completedFiles++
        this.updateProgress((completedFiles / totalFiles) * 100, `Uploaded ${completedFiles} of ${totalFiles} files`)
      }
      
      // Refresh the page or update the images container
      this.hideProgress()
      this.refreshImages()
      this.resetFileInput()
      
    } catch (error) {
      this.hideProgress()
      this.showError('Upload failed. Please try again.')
      console.error('Upload error:', error)
    }
  }

  uploadSingleFile(file) {
    return new Promise((resolve, reject) => {
      const formData = new FormData()
      formData.append('file', file)
      
      const xhr = new XMLHttpRequest()
      
      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable) {
          const percentComplete = (event.loaded / event.total) * 100
          this.updateProgress(percentComplete, `Uploading ${file.name}...`)
        }
      })
      
      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          // Handle Turbo Stream response
          if (xhr.getResponseHeader('Content-Type')?.includes('text/vnd.turbo-stream.html')) {
            // Let Turbo handle the stream response
            const event = new CustomEvent('turbo:before-stream-render', {
              detail: { newStream: xhr.responseText }
            })
            document.dispatchEvent(event)
            
            // Manually process the turbo stream
            Turbo.renderStreamMessage(xhr.responseText)
          }
          resolve(xhr.responseText)
        } else {
          reject(new Error(`HTTP ${xhr.status}: ${xhr.statusText}`))
        }
      })
      
      xhr.addEventListener('error', () => {
        reject(new Error('Network error occurred'))
      })
      
      // Get the form action URL
      const formAction = this.formTarget.action
      
      xhr.open('POST', formAction)
      
      // Add CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      if (csrfToken) {
        xhr.setRequestHeader('X-CSRF-Token', csrfToken)
      }
      
      // Set headers for Rails and Turbo Stream
      xhr.setRequestHeader('Accept', 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml')
      xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
      
      xhr.send(formData)
    })
  }

  showProgress() {
    this.progressContainerTarget.classList.remove('hidden')
  }

  hideProgress() {
    this.progressContainerTarget.classList.add('hidden')
  }

  updateProgress(percent, text) {
    this.progressBarTarget.style.width = `${percent}%`
    this.progressTextTarget.textContent = text
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorContainerTarget.classList.remove('hidden')
  }

  hideError() {
    this.errorContainerTarget.classList.add('hidden')
  }

  resetFileInput() {
    this.fileInputTarget.value = ''
  }

  refreshImages() {
    // With Turbo Streams, we don't need to manually refresh
    // The server will send the appropriate Turbo Stream updates
    console.log('Images updated via Turbo Stream')
  }

  // Handle individual image deletion
  deleteImage(event) {
    if (!confirm('Are you sure you want to delete this image?')) {
      event.preventDefault()
    }
  }
}