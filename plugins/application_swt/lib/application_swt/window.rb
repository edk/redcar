
module Redcar
  class ApplicationSWT
    class Window
      attr_reader :shell, :window, :shell_listener
      
      class ShellListener
        include ListenerHelpers
        
        def initialize(controller)
          @controller = controller
        end
        
        def shell_closed(e)
          ignore_within_self do
            e.doit = false
            @controller.swt_event_closed
          end
        end

        def shell_activated(e)
          ignore_within_self do
            e.doit = false
            @controller.swt_event_activated
          end
        end
        
        def shell_deactivated(_); end
        def shell_deiconified(_); end
        def shell_iconified(_); end
      end
      
      def initialize(window)
        @window = window
      	@notebook_handlers = Hash.new {|h,k| h[k] = []}
        create_shell
        create_sashes(window)
        new_notebook(window.notebooks.first)
        add_listeners
        create_treebook_controller
        reset_sash_widths
        @treebook_unopened = true
      end
      
      def add_listeners
        @window.add_listener(:show,          &method(:show))
        @window.add_listener(:menu_changed,  &method(:menu_changed))
        @window.add_listener(:popup_menu,    &method(:popup_menu))
        @window.add_listener(:title_changed, &method(:title_changed))
        @window.add_listener(:new_notebook,  &method(:new_notebook))
        @window.add_listener(:notebook_removed,  &method(:notebook_removed))
        @window.add_listener(:closed,        &method(:closed))
        method = method(:notebook_orientation_changed)
        @window.add_listener(:notebook_orientation_changed, &method)
        @window.add_listener(:focussed,      &method(:focussed))
        
        @window.treebook.add_listener(:tree_added) do
          if @treebook_unopened
            reset_sash_widths
            @treebook_unopened = false
          end
        end
        
        @window.treebook.add_listener(:tree_removed) do
          reset_sash_widths
        end
      end
        
      def create_treebook_controller
        treebook = @window.treebook
        controller = ApplicationSWT::Treebook.new(
          @tree_composite, 
          @tree_layout, 
          treebook)
        treebook.controller = controller
      end
      
      def show
        @shell.open
        @shell.text = window.title
      end
      
      def menu_changed(menu)
        @menu_controller = ApplicationSWT::Menu.new(self, menu, Swt::SWT::BAR)
        shell.menu_bar = @menu_controller.menu_bar
      end
      
      def popup_menu(menu)
        menu.controller = ApplicationSWT::Menu.new(self, menu, Swt::SWT::POP_UP)
        menu.controller.show
      end
      
      def title_changed(new_title)
        @shell.text = new_title
      end
      
      def new_notebook(notebook_model)
        notebook_controller = ApplicationSWT::Notebook.new(notebook_model, @notebook_sash)
        reset_notebook_sash_widths
      end
      
      def notebook_removed(notebook_model)
        notebook_controller = notebook_model.controller
        @notebook_handlers[notebook_model].each do |h|
          notebook_controller.remove_listener(h)
        end
        notebook_controller.dispose
        reset_notebook_sash_widths
      end
      
      def notebook_orientation_changed(new_orientation)
        orientation = horizontal_vertical(new_orientation)
        @notebook_sash.setOrientation(orientation)
      end
      
      def focussed(_)
        @shell.set_active
      end
      
      def closed(_)
        @shell.close
        @menu_controller.close
      end
      
      def dispose
        @shell.dispose
        @menu_controller.close
      end
        
      def swt_event_closed
        @window.close
      end
        
      def swt_event_activated
        @window.focus
      end
      
      private
      
      SASH_WIDTH = 5
      TREEBOOK_WIDTH = 20
      
      def create_shell
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
        @shell.layout = Swt::Layout::GridLayout.new(1, false)
      	@shell_listener = ShellListener.new(self)
        @shell.add_shell_listener(@shell_listener)  
      end
      
      def create_sashes(window_model)
        orientation = horizontal_vertical(window_model.notebook_orientation)
        @sash     = Swt::Custom::SashForm.new(@shell, orientation)
        grid_data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH)
      	@sash.setLayoutData(grid_data)
      	@sash.setSashWidth(0)
      	
      	@tree_composite = Swt::Widgets::Composite.new(@sash, Swt::SWT::NONE)
      	@tree_layout = Swt::Custom::StackLayout.new
      	@tree_composite.setLayout(@tree_layout)
      	button = Swt::Widgets::Button.new(@tree_composite, Swt::SWT::PUSH)
      	button.setText("Button in pane2")
      	@tree_layout.topControl = button
      	
        @notebook_sash     = Swt::Custom::SashForm.new(@sash, orientation)
        grid_data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH)
      	@notebook_sash.setLayoutData(grid_data)
      	@notebook_sash.setSashWidth(SASH_WIDTH)
      end
      
      def horizontal_vertical(symbol)
        case symbol
        when :horizontal
          Swt::SWT::HORIZONTAL
        when :vertical
          Swt::SWT::VERTICAL
        end
      end
      
      def reset_sash_widths
        if @window.treebook.trees.any?
          @sash.setWeights([TREEBOOK_WIDTH, 100 - TREEBOOK_WIDTH].to_java(:int))
          @sash.setSashWidth(SASH_WIDTH)
        else
          @sash.setWeights([0,100].to_java(:int))
          @sash.setSashWidth(0)
          @treebook_unopened = true
        end
      end
      
      def reset_notebook_sash_widths
        width = (100/@window.notebooks.length).to_i
        widths = [width]*@window.notebooks.length
      	@notebook_sash.setWeights(widths.to_java(:int))
    	end
    end
  end
end
