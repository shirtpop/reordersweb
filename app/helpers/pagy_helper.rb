module PagyHelper
  def pagy_tailwind_nav(pagy, pagy_id: nil, link_extra: "", **vars)
    pagy_id = %{id="#{pagy_id}"} if pagy_id
    
    html = +%{<nav #{pagy_id} class="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6 dark:bg-gray-800 dark:border-gray-700" aria-label="Pagination">}
    html << pagy_tailwind_prev_next(pagy, link_extra)
    html << pagy_tailwind_nav_compact(pagy, link_extra)
    html << %{</nav>}
  end

  private

  def pagy_tailwind_prev_next(pagy, link_extra)
    html = +%{<div class="flex flex-1 justify-between sm:hidden">}
    
    if pagy.prev
      html << %{<a href="#{pagy_url_for(pagy, pagy.prev)}" #{link_extra} class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700">Previous</a>}
    else
      html << %{<span class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-300 cursor-not-allowed dark:bg-gray-800 dark:border-gray-600">Previous</span>}
    end
    
    if pagy.next
      html << %{<a href="#{pagy_url_for(pagy, pagy.next)}" #{link_extra} class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700">Next</a>}
    else
      html << %{<span class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-300 cursor-not-allowed dark:bg-gray-800 dark:border-gray-600">Next</span>}
    end
    
    html << %{</div>}
  end

  def pagy_tailwind_nav_compact(pagy, link_extra)
    html = +%{<div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">}
    html << %{<div><p class="text-sm text-gray-700 dark:text-gray-300">Showing <span class="font-medium">#{pagy.from}</span> to <span class="font-medium">#{pagy.to}</span> of <span class="font-medium">#{pagy.count}</span> results</p></div>}
    html << %{<div><nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">}
    
    # Previous button
    if pagy.prev
      html << %{<a href="#{pagy_url_for(pagy, pagy.prev)}" #{link_extra} class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0 dark:ring-gray-600 dark:text-gray-300 dark:hover:bg-gray-700">}
      html << %{<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" /></svg>}
      html << %{<span class="sr-only">Previous</span></a>}
    else
      html << %{<span class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-300 ring-1 ring-inset ring-gray-300 cursor-not-allowed dark:ring-gray-600">}
      html << %{<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" /></svg>}
      html << %{<span class="sr-only">Previous</span></span>}
    end
    
    # Page numbers
    pagy.series.each do |item|
      case item
      when Integer
        if item == pagy.page
          html << %{<span aria-current="page" class="relative z-10 inline-flex items-center bg-blue-600 px-4 py-2 text-sm font-semibold text-white focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600">#{item}</span>}
        else
          html << %{<a href="#{pagy_url_for(pagy, item)}" #{link_extra} class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0 dark:text-gray-300 dark:ring-gray-600 dark:hover:bg-gray-700">#{item}</a>}
        end
      when String
        html << %{<span class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0 dark:text-gray-300 dark:ring-gray-600 bg-gray-700">#{item}</span>}
      end
    end
    
    # Next button
    if pagy.next
      html << %{<a href="#{pagy_url_for(pagy, pagy.next)}" #{link_extra} class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0 dark:ring-gray-600 dark:text-gray-300 dark:hover:bg-gray-700">}
      html << %{<span class="sr-only">Next</span><svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" /></path></svg></a>}
    else
      html << %{<span class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-300 ring-1 ring-inset ring-gray-300 cursor-not-allowed dark:ring-gray-600">}
      html << %{<span class="sr-only">Next</span><svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" /></path></svg></span>}
    end
    
    html << %{</nav></div></div>}
  end
end