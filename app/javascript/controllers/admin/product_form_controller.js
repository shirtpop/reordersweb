// app/javascript/controllers/product_form_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="product-form"
export default class extends Controller {
  static targets = [
    "bulkPricesContainer", 
    "bulkPriceTemplate", 
    "bulkPriceRow", 
    "colorsContainer", 
    "colorTemplate", 
    "colorRow",
    "descriptionField"
  ]

  connect() {
    // Sync existing color pickers with text inputs
    this.syncExistingColorInputs()
    // Initialize WYSIWYG editor
    this.initializeWysiwygEditor()
  }

  addBulkPrice() {
    const template = this.bulkPriceTemplateTarget.content.cloneNode(true)
    this.bulkPricesContainerTarget.appendChild(template)
  }

  removeBulkPrice(event) {
    event.target.closest('.bulk-price-row').remove()
  }

  addColor() {
    const template = this.colorTemplateTarget.content.cloneNode(true)
    this.colorsContainerTarget.appendChild(template)
    
    // Sync color picker with text input for the newly added row
    const colorRow = this.colorsContainerTarget.lastElementChild
    this.syncColorInputs(colorRow)
  }

  removeColor(event) {
    event.target.closest('.color-row').remove()
  }

  // Private methods
  syncExistingColorInputs() {
    this.colorRowTargets.forEach(row => {
      this.syncColorInputs(row)
    })
  }

  syncColorInputs(colorRow) {
    const colorInput = colorRow.querySelector('input[type="color"]')
    const textInput = colorRow.querySelector('input[type="text"]')
    
    if (colorInput && textInput) {
      // Update text input when color picker changes
      colorInput.addEventListener('input', (e) => {
        textInput.value = e.target.value.toUpperCase()
      })
      
      // Update color picker when text input changes (if valid hex)
      textInput.addEventListener('input', (e) => {
        const hexValue = e.target.value.trim()
        if (this.isValidHexColor(hexValue)) {
          colorInput.value = hexValue
        }
      })
    }
  }

  isValidHexColor(hex) {
    return /^#[0-9A-F]{6}$/i.test(hex)
  }

  async initializeWysiwygEditor() {
    try {
      // Load required modules dynamically
      const [
        { Editor },
        StarterKit,
        Highlight,
        Underline,
        Link,
        TextAlign,
        Bold
      ] = await Promise.all([
        import('https://esm.sh/@tiptap/core@2.6.6'),
        import('https://esm.sh/@tiptap/starter-kit@2.6.6').then(m => m.default),
        import('https://esm.sh/@tiptap/extension-highlight@2.6.6').then(m => m.default),
        import('https://esm.sh/@tiptap/extension-underline@2.6.6').then(m => m.default),
        import('https://esm.sh/@tiptap/extension-link@2.6.6').then(m => m.default),
        import('https://esm.sh/@tiptap/extension-text-align@2.6.6').then(m => m.default),
        import('https://esm.sh/@tiptap/extension-bold@2.6.6').then(m => m.default)
      ])

      // Custom Bold extension to ensure proper rendering
      const CustomBold = Bold.extend({
        renderHTML({ HTMLAttributes }) {
          return ['span', { ...HTMLAttributes, style: 'font-weight: bold;' }, 0];
        },
        excludes: '',
      })

      // Initialize the editor
      this.editor = new Editor({
        element: document.querySelector('#product_description_wysiwyg'),
        extensions: [
          StarterKit.configure({
            bold: false, // Use custom bold instead
          }),
          CustomBold,
          Highlight,
          Underline,
          Link.configure({
            openOnClick: false,
            autolink: true,
            defaultProtocol: 'https',
          }),
          TextAlign.configure({
            types: ['heading', 'paragraph'],
          })
        ],
        content: this.descriptionFieldTarget.value || '<p>Enter your product description here...</p>',
        editorProps: {
          attributes: {
            class: 'format lg:format-lg dark:format-invert focus:outline-none format-blue max-w-none prose prose-sm sm:prose lg:prose-lg xl:prose-2xl mx-auto focus:outline-none',
          },
        },
        onUpdate: ({ editor }) => {
          // Update the hidden field with the editor content
          this.descriptionFieldTarget.value = editor.getHTML()
        }
      })

      // Set up event listeners for toolbar buttons
      this.setupToolbarButtons()

    } catch (error) {
      console.error('Failed to initialize WYSIWYG editor:', error)
      // Fallback to regular textarea if editor fails to load
      this.setupFallbackTextarea()
    }
  }

  setupToolbarButtons() {
    const buttons = [
      { id: 'toggleBoldButton', action: () => this.editor.chain().focus().toggleBold().run() },
      { id: 'toggleItalicButton', action: () => this.editor.chain().focus().toggleItalic().run() },
      { id: 'toggleUnderlineButton', action: () => this.editor.chain().focus().toggleUnderline().run() },
      { id: 'toggleListButton', action: () => this.editor.chain().focus().toggleBulletList().run() },
      { id: 'toggleOrderedListButton', action: () => this.editor.chain().focus().toggleOrderedList().run() }
    ]

    buttons.forEach(({ id, action }) => {
      const button = document.getElementById(id)
      if (button) {
        button.addEventListener('click', (e) => {
          e.preventDefault()
          action()
        })
      }
    })
  }

  setupFallbackTextarea() {
    const editorContainer = document.querySelector('#product_description_wysiwyg')
    if (editorContainer) {
      editorContainer.innerHTML = `
        <textarea 
          name="product[description]" 
          rows="6" 
          class="w-full px-0 text-sm text-gray-800 bg-white border-0 dark:bg-gray-800 focus:ring-0 dark:text-white dark:placeholder-gray-400 resize-none"
          placeholder="Enter your product description here..."
        >${this.descriptionFieldTarget.value || ''}</textarea>
      `
    }
  }

  disconnect() {
    // Clean up the editor when controller is disconnected
    if (this.editor) {
      this.editor.destroy()
    }
  }
}