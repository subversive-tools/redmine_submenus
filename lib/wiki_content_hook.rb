require 'nokogiri'

module WikiContentHook
  class ViewWikiContentHook < Redmine::Hook::ViewListener
    def view_wiki_show_content(context={})
      # Check if the setting to show subwiki menu is enabled
      if Setting.plugin_redmine_submenus['show_subwiki_menu']
        # Render the original wiki content to a string
        content_html = context[:controller].send(:render_to_string, {
          partial: 'wiki/content',
          locals: context
        })

        # Modify the content to include the dropdown menu
        modified_content = modify_wiki_content(content_html, context[:page])
        modified_content.html_safe
      else
        # If the setting is off, return the original content
        context[:controller].send(:render_to_string, {
          partial: 'wiki/content',
          locals: context
        }).html_safe
      end
    end

    private

    def modify_wiki_content(content_html, page)
      # Parse the HTML content
      doc = Nokogiri::HTML.fragment(content_html)
      h1 = doc.at('h1')

      # Check if there is an h1 element and if the page has child pages
      if h1 && page.children.present?
        # Extract the original text and anchor element
        original_text_node = h1.xpath('text()').first
        anchor = h1.at('a.wiki-anchor')

        # Generate the new dropdown menu
        dropdown_menu = generate_dropdown_menu(page.children, original_text_node.text.strip)

        # Replace the text node with the new span element containing the dropdown menu
        original_text_node.replace(Nokogiri::HTML.fragment(dropdown_menu))
        
        # Add the original anchor element back to the h1 element
        h1.add_child(anchor) if anchor
      end

      # Return the modified HTML
      doc.to_html
    end

    def generate_dropdown_menu(children, original_title)
      # Retrieve the dropdown menu symbol from settings or use default
      menu_symbol = Setting.plugin_redmine_submenus['dropdown_menu_symbol'] || '…'
      
      # Generate the dropdown content with links to child pages
      dropdown_content = children.map do |child|
        link_to(child.title, project_wiki_page_path(child.project, child.title), class: 'drdn-link')
      end.join.html_safe

      # Create the complete dropdown menu HTML
      dropdown_menu = <<-HTML
        <span class="drdn">
          <span class="current-page drdn-trigger">#{h(original_title)} #{menu_symbol}</span>
          <div class="drdn-content contextual">
            <div class="drdn-items">
              #{dropdown_content}
            </div>
          </div>
        </span>
      HTML

      dropdown_menu
    end

    # Method to escape HTML text
    def h(text)
      CGI.escapeHTML(text.to_s)
    end

    # Method to generate a link element with given title and URL
    def link_to(title, url, options = {})
      "<a href=\"#{url}\" #{options.map { |key, value| "#{key}=\"#{value}\"" }.join(' ')}>#{h(title)}</a>".html_safe
    end
  end
end
