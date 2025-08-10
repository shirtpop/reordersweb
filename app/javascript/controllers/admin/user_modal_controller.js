import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal", "clientField", "errorContainer", "errorList", 
    "submitButton", "tableContainer", "roleSelect", "modalTitle",
    "viewContent", "formContent", "viewFooter", "formFooter",
    "viewEmail", "viewRole", "viewClient", "viewCreated", "viewClientContainer",
    "emailField", "passwordField", "passwordConfirmationField", 
    "clientSearchField", "clientIdField", "passwordFields", "editButton"
  ]

  connect() {
    this.boundHandleEscape = this.handleEscape.bind(this)
    this.isSubmitting = false
    this.currentMode = null // 'create', 'edit', 'view'
    this.currentUserId = null
    this.setupFormValidation()
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  // Open modal for creating new user
  openCreateModal(event) {
    event.preventDefault()
    this.currentMode = 'create'
    this.currentUserId = null
    this.setModalTitle("Add New User")
    this.showFormMode()
    this.resetForm()
    this.setSubmitButtonText("Create User")
    this.showPasswordFields()
    this.openModal()
  }

  // Open modal for viewing user
  openViewModal(event) {
    event.preventDefault()
    this.currentMode = 'view'
    this.currentUserId = event.currentTarget.dataset.userId
    
    const userData = {
      email: event.currentTarget.dataset.userEmail,
      role: event.currentTarget.dataset.userRole,
      client: event.currentTarget.dataset.userClient,
      created: event.currentTarget.dataset.userCreated
    }
    
    this.setModalTitle("View User")
    this.showViewMode()
    this.populateViewData(userData)
    this.openModal()
  }

  // Open modal for editing user
  openEditModal(event) {
    event.preventDefault()
    this.currentMode = 'edit'
    this.currentUserId = event.currentTarget.dataset.userId
    
    const userData = {
      email: event.currentTarget.dataset.userEmail,
      role: event.currentTarget.dataset.userRole,
      clientId: event.currentTarget.dataset.userClientId,
      clientName: event.currentTarget.dataset.userClientName
    }
    
    this.setModalTitle("Edit User")
    this.showFormMode()
    this.populateFormData(userData)
    this.setSubmitButtonText("Update User")
    this.hidePasswordFields()
    this.updateFormAction()
    this.openModal()
  }

  // Switch from view to edit mode
  switchToEdit(event) {
    event.preventDefault()
    
    // Get current user data from view mode
    const userData = {
      email: this.viewEmailTarget.textContent,
      role: this.viewRoleTarget.textContent.toLowerCase(),
      clientId: this.currentUserId, // We'll need to fetch this properly
      clientName: this.hasViewClientTarget ? this.viewClientTarget.textContent : null
    }
    
    this.currentMode = 'edit'
    this.setModalTitle("Edit User")
    this.showFormMode()
    this.populateFormData(userData)
    this.setSubmitButtonText("Update User")
    this.hidePasswordFields()
    this.updateFormAction()
  }

  openModal() {
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.boundHandleEscape)
    
    this.hideErrors()
    
    if (this.currentMode !== 'view') {
      const firstInput = this.formTarget.querySelector('input[type="email"]')
      if (firstInput) {
        setTimeout(() => firstInput.focus(), 100)
      }
    }
  }

  closeModal(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.boundHandleEscape)
    
    this.resetForm()
    this.hideErrors()
    this.currentMode = null
    this.currentUserId = null
  }

  setModalTitle(title) {
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = title
    }
  }

  showViewMode() {
    if (this.hasViewContentTarget) this.viewContentTarget.classList.remove("hidden")
    if (this.hasFormContentTarget) this.formContentTarget.classList.add("hidden")
    if (this.hasViewFooterTarget) this.viewFooterTarget.classList.remove("hidden")
    if (this.hasFormFooterTarget) this.formFooterTarget.classList.add("hidden")
  }

  showFormMode() {
    if (this.hasViewContentTarget) this.viewContentTarget.classList.add("hidden")
    if (this.hasFormContentTarget) this.formContentTarget.classList.remove("hidden")
    if (this.hasViewFooterTarget) this.viewFooterTarget.classList.add("hidden")
    if (this.hasFormFooterTarget) this.formFooterTarget.classList.remove("hidden")
  }

  populateViewData(userData) {
    if (this.hasViewEmailTarget) this.viewEmailTarget.textContent = userData.email
    if (this.hasViewRoleTarget) {
      this.viewRoleTarget.innerHTML = `
        <span class="${userData.role === 'admin' ? 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300' : 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300'} text-xs font-medium px-2.5 py-0.5 rounded">
          ${userData.role.charAt(0).toUpperCase() + userData.role.slice(1)}
        </span>
      `
    }
    if (this.hasViewCreatedTarget) this.viewCreatedTarget.textContent = userData.created

    // Handle client field
    if (userData.client && userData.client !== 'null' && userData.client !== '') {
      if (this.hasViewClientTarget) this.viewClientTarget.textContent = userData.client
      if (this.hasViewClientContainerTarget) this.viewClientContainerTarget.classList.remove("hidden")
    } else {
      if (this.hasViewClientContainerTarget) this.viewClientContainerTarget.classList.add("hidden")
    }
  }

  populateFormData(userData) {
    if (this.hasEmailFieldTarget) this.emailFieldTarget.value = userData.email
    if (this.hasRoleSelectTarget) this.roleSelectTarget.value = userData.role
    
    // Handle client field
    if (userData.role === 'client' && userData.clientId && userData.clientName) {
      this.showClientField()
      if (this.hasClientSearchFieldTarget) this.clientSearchFieldTarget.value = userData.clientName
      if (this.hasClientIdFieldTarget) this.clientIdFieldTarget.value = userData.clientId
    } else if (userData.role === 'client') {
      this.showClientField()
    } else {
      this.hideClientField()
    }
  }

  updateFormAction() {
    if (this.currentMode === 'edit' && this.currentUserId) {
      const form = this.formTarget
      form.action = `/admin/users/${this.currentUserId}`
      
      // Add method override for PATCH
      let methodField = form.querySelector('input[name="_method"]')
      if (!methodField) {
        methodField = document.createElement('input')
        methodField.type = 'hidden'
        methodField.name = '_method'
        form.appendChild(methodField)
      }
      methodField.value = 'patch'
    }
  }

  resetForm() {
    if (this.hasFormTarget) {
      this.formTarget.reset()
      this.formTarget.action = '/admin/users' // Reset to create action
      
      // Remove method override
      const methodField = this.formTarget.querySelector('input[name="_method"]')
      if (methodField) methodField.remove()
    }
    
    this.isSubmitting = false
    this.setSubmitButtonState(false)
    this.hideClientField()
    
    if (this.hasRoleSelectTarget) {
      this.roleSelectTarget.selectedIndex = 0
    }
  }

  setSubmitButtonText(text) {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.value = text
    }
  }

  showPasswordFields() {
    if (this.hasPasswordFieldsTarget) {
      this.passwordFieldsTarget.classList.remove("hidden")
      if (this.hasPasswordFieldTarget) this.passwordFieldTarget.required = true
      if (this.hasPasswordConfirmationFieldTarget) this.passwordConfirmationFieldTarget.required = true
    }
  }

  hidePasswordFields() {
    if (this.hasPasswordFieldsTarget) {
      this.passwordFieldsTarget.classList.add("hidden")
      if (this.hasPasswordFieldTarget) {
        this.passwordFieldTarget.required = false
        this.passwordFieldTarget.value = ""
      }
      if (this.hasPasswordConfirmationFieldTarget) {
        this.passwordConfirmationFieldTarget.required = false
        this.passwordConfirmationFieldTarget.value = ""
      }
    }
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.isSubmitting) {
      this.closeModal()
    }
  }

  handleFormSubmissionStart(event) {
    this.setSubmitButtonState(true)
    this.hideErrors()
  }

  handleFormSubmission(event) {
    const detail = event.detail
    const response = detail.fetchResponse.response
    
    this.setSubmitButtonState(false)
    this.isSubmitting = false

    if (response.ok) {
      this.handleSuccess()
    } else {
      this.handleError(detail)
    }
  }

  async handleSuccess() {
    const message = this.currentMode === 'edit' ? "User updated successfully!" : "User created successfully!"
    this.showSuccessMessage(message)
    this.closeModal()
    
    if (this.currentMode === 'edit') {
      await this.updateTableRow()
    } else {
      await this.refreshTable()
    }
  }

  async handleError(detail) {
    try {
      const errorData = await detail.fetchResponse.response.json()
      
      if (errorData.errors && Array.isArray(errorData.errors)) {
        this.showErrors(errorData.errors)
      } else {
        this.showErrors(["An error occurred while saving the user."])
      }
    } catch (e) {
      this.showErrors(["An unexpected error occurred. Please try again."])
    }
  }

  async updateTableRow() {
    // For edit mode, we could update just the specific row
    // For simplicity, we'll refresh the entire table
    await this.refreshTable()
  }

  showErrors(errors) {
    if (!this.hasErrorContainerTarget || !this.hasErrorListTarget) return
    
    this.errorListTarget.innerHTML = ""
    
    errors.forEach(error => {
      const li = document.createElement("li")
      li.textContent = error
      this.errorListTarget.appendChild(li)
    })
    
    this.errorContainerTarget.classList.remove("hidden")
    
    const modalBody = this.modalTarget.querySelector('.relative > div')
    if (modalBody) {
      modalBody.scrollTop = 0
    }
  }

  hideErrors() {
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.classList.add("hidden")
    }
  }

  showSuccessMessage(message) {
    const notification = document.createElement("div")
    notification.className = "fixed top-4 right-4 z-50 flex items-center p-4 mb-4 text-green-800 rounded-lg bg-green-50 dark:bg-gray-800 dark:text-green-400 shadow-lg transform transition-all duration-300 translate-x-full"
    notification.innerHTML = `
      <svg class="flex-shrink-0 w-4 h-4" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
        <path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5ZM9.5 4a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM12 15H8a1 1 0 0 1 0-2h1v-3H8a1 1 0 0 1 0-2h2a1 1 0 0 1 1 1v4h1a1 1 0 0 1 0 2Z"/>
      </svg>
      <div class="ms-3 text-sm font-medium">${message}</div>
      <button type="button" class="ms-auto -mx-1.5 -my-1.5 bg-green-50 text-green-500 rounded-lg focus:ring-2 focus:ring-green-400 p-1.5 hover:bg-green-200 inline-flex items-center justify-center h-8 w-8 dark:bg-gray-800 dark:text-green-400 dark:hover:bg-gray-700" onclick="this.parentElement.remove()">
        <span class="sr-only">Close</span>
        <svg class="w-3 h-3" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 14 14">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"/>
        </svg>
      </button>
    `
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.classList.remove('translate-x-full')
      notification.classList.add('translate-x-0')
    }, 100)
    
    // Auto remove after 4 seconds
    setTimeout(() => {
      notification.classList.add('translate-x-full')
      setTimeout(() => notification.remove(), 300)
    }, 4000)
  }

  async refreshTable() {
    try {
      const response = await fetch(window.location.pathname, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const html = await response.text()
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const newTable = doc.querySelector('[data-user-modal-target="tableContainer"]')
        
        if (newTable && this.hasTableContainerTarget) {
          this.tableContainerTarget.innerHTML = newTable.innerHTML
        }
      }
    } catch (error) {
      console.error('Error refreshing table:', error)
      window.location.reload()
    }
  }

  setSubmitButtonState(loading) {
    if (!this.hasSubmitButtonTarget) return
    
    if (loading) {
      this.submitButtonTarget.disabled = true
      const buttonText = this.currentMode === 'edit' ? 'Updating...' : 'Creating...'
      this.submitButtonTarget.innerHTML = `
        <svg class="animate-spin -ml-1 mr-3 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        ${buttonText}
      `
      this.isSubmitting = true
    } else {
      this.submitButtonTarget.disabled = false
      const buttonText = this.currentMode === 'edit' ? 'Update User' : 'Create User'
      this.submitButtonTarget.value = buttonText
      this.isSubmitting = false
    }
  }

  toggleClientField(event) {
    const roleSelect = event.target
    const selectedRole = roleSelect.value
    
    if (selectedRole === "client") {
      this.showClientField()
    } else {
      this.hideClientField()
    }
  }

  showClientField() {
    if (this.hasClientFieldTarget) {
      this.clientFieldTarget.classList.remove("hidden")
      if (this.hasClientSearchFieldTarget) {
        this.clientSearchFieldTarget.required = true
      }
    }
  }

  hideClientField() {
    if (this.hasClientFieldTarget) {
      this.clientFieldTarget.classList.add("hidden")
      if (this.hasClientSearchFieldTarget) {
        this.clientSearchFieldTarget.required = false
        this.clientSearchFieldTarget.value = ""
      }
      if (this.hasClientIdFieldTarget) {
        this.clientIdFieldTarget.value = ""
      }
    }
  }

  setupFormValidation() {
    const form = this.formTarget
    const inputs = form.querySelectorAll('input[required], select[required]')
    
    inputs.forEach(input => {
      input.addEventListener('blur', this.validateField.bind(this))
      input.addEventListener('input', this.clearFieldError.bind(this))
    })
  }

  validateField(event) {
    const field = event.target
    const isValid = field.checkValidity()
    
    if (!isValid) {
      field.classList.add('border-red-500')
      field.classList.remove('border-gray-300')
    } else {
      field.classList.remove('border-red-500')
      field.classList.add('border-gray-300')
    }
  }

  clearFieldError(event) {
    const field = event.target
    field.classList.remove('border-red-500')
    field.classList.add('border-gray-300')
  }
}