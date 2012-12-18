using Gtk;

class MainWindow : ApplicationWindow {
	public static const int PAGE_STREAM    = 0;
	public static const int PAGE_MENTIONS  = 1;
	public static const int PAGE_FAVORITES = 2;
	public static const int PAGE_SEARCH    = 3;


	private Toolbar left_toolbar                  = new Toolbar();
	private Toolbar primary_toolbar 			  = new Toolbar();
	private Box main_box                          = new Box(Orientation.VERTICAL, 0);
	private Box bottom_box                        = new Box(Orientation.HORIZONTAL, 0);
	private Notebook main_notebook                = new Notebook();
	private RadioToolButton[] switch_page_buttons = new RadioToolButton[4];
	private TweetContainer[] containers			  = new TweetContainer[4];
	private ToolButton avatar_button			  = new ToolButton(null, null);
	private ToolButton refresh_button			  = new ToolButton.from_stock(Stock.REFRESH);
	private ToolButton settings_button			  = new ToolButton.from_stock(Stock.PROPERTIES);
	private ToolButton new_tweet_button			  = new ToolButton.from_stock(Stock.NEW);
	private SeparatorToolItem expander_item		  = new SeparatorToolItem();
	private SeparatorToolItem left_separator	  = new SeparatorToolItem();

	public MainWindow(Gtk.Application app){
		GLib.Object (application: app);

		containers[0] = new StreamContainer();
		containers[1] = new MentionsContainer();
		containers[2] = new FavoriteContainer();
		containers[3] = new SearchContainer();

		/** Initialize all containers */
		foreach(var tc in containers){
			tc.set_main_window(this);
			tc.create_tool_button();
		}

		//Load the user's sceen_name used for identifying him
		User.load();
		//Update the Twitter config
		Twitter.update_config.begin();

		this.delete_event.connect(() => {
			message("destroy.");
			NotificationManager.uninit();
			// if (Settings.show_tray_icon()){
				// 'Minimize to tray'
				// set_visible(false);
			// }else{
				save_geometry();
				// Gtk.main_quit();
				this.application.release();
			// }
			return true;
		});

		new_tweet_button.clicked.connect( () => {
		 	NewTweetWindow win = new NewTweetWindow(this);
			win.show_all();

		});

		//Load custom style sheet
		try{
			CssProvider provider = new CssProvider();
			provider.load_from_file(File.new_for_path("ui/style.css"));
			Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
		                                         STYLE_PROVIDER_PRIORITY_APPLICATION);
		}catch(GLib.Error e){
			warning("Error while loading ui/style.css: %s", e.message);
		}

		left_toolbar.orientation = Orientation.VERTICAL;
		left_toolbar.set_style(ToolbarStyle.ICONS);

		primary_toolbar.orientation = Orientation.HORIZONTAL;
		primary_toolbar.set_style(ToolbarStyle.ICONS);
		primary_toolbar.get_style_context().add_class("primary-toolbar");
		primary_toolbar.set_visible(true);


		expander_item.draw = false;
		expander_item.set_expand(true);


		avatar_button.set_icon_widget(new Image.from_file(User.get_avatar_path()));
		avatar_button.clicked.connect( () => {
			ProfileDialog pd = new ProfileDialog();
			pd.show_all();
		});

		//Update the user's info
		User.update_info.begin((Image)avatar_button.icon_widget);

		foreach(var tc in containers){
			left_toolbar.add(tc.get_tool_button());
		}

		refresh_button.clicked.connect( () => {
			//Refresh the current container
		});
		settings_button.clicked.connect( () => {
			SettingsDialog sd = new SettingsDialog(this);
			sd.show_all();
		});
		bottom_box.pack_start(left_toolbar, false, true);

		if (Settings.show_primary_toolbar()){
			main_box.pack_start(primary_toolbar, false, false);
			setup_primary_toolbar();
		}else{
			setup_left_toolbar();
		}


		// tweet_scroller.vadjustment.value_changed.connect( () => {
		// 	int max = (int)(tweet_scroller.vadjustment.upper - tweet_scroller.vadjustment.page_size);
		// 	int value = (int)tweet_scroller.vadjustment.value;
		// 	if (value >= (max * 0.9f)){
		// 		//Load older tweets
		// 		message("end!");
		// 	}
		// });


		foreach(var tc in containers){
			main_notebook.append_page(tc);
		}

		main_notebook.show_tabs   = false;
		main_notebook.show_border = false;
		bottom_box.pack_end (main_notebook, true, true);
		main_box.pack_end(bottom_box, true, true);


		this.add(main_box);
		this.load_geometry();
		this.show_all();
	}

	public void switch_to_search(string search_term){
		//search_container.search_for.begin(search_term, true);
		switch_page_buttons[PAGE_SEARCH].active = true;
		main_notebook.set_current_page(PAGE_SEARCH);
	}

	/**
	 * Adds/inserts the widgets into the left toolbar.
	 */
	private void setup_left_toolbar(){
		left_toolbar.get_style_context().remove_class("sidebar");
		left_toolbar.get_style_context().add_class("primary-toolbar");
		
		left_toolbar.insert(avatar_button, 0);
		left_toolbar.insert(new_tweet_button, 1);
		left_toolbar.insert(left_separator, 2);
		left_toolbar.add(expander_item);
		left_toolbar.add(refresh_button);
		left_toolbar.add(settings_button);
	}

	/**
	 * Adds/inserts the widgets into the primary toolbar
	 */
	private void setup_primary_toolbar(){
		primary_toolbar.add(avatar_button);
		primary_toolbar.add(new_tweet_button);
		primary_toolbar.add(expander_item);
		primary_toolbar.add(refresh_button);
		primary_toolbar.add(settings_button);	
		//Make the left toolbar a sidebar
		left_toolbar.get_style_context().remove_class("primary-toolbar");
		left_toolbar.get_style_context().add_class("sidebar");
	}

	public void set_show_primary_toolbar(bool show_primary_toolbar){
		// We just ASSUME that this value only toggles and that 2 subsequent calls NEVER have the
		// same value of show_primary_toolbar.
		if(show_primary_toolbar){
			main_box.pack_start(primary_toolbar, false, false);
			//Remove widgets
			left_toolbar.remove(avatar_button);
			left_toolbar.remove(settings_button);
			left_toolbar.remove(refresh_button);
			left_toolbar.remove(new_tweet_button);
			left_toolbar.remove(expander_item);
			left_toolbar.remove(left_separator);
			//Add them again
			setup_primary_toolbar();
		}else{
			main_box.remove(primary_toolbar);
			//Remove widgets
			primary_toolbar.remove(avatar_button);
			primary_toolbar.remove(new_tweet_button);
			primary_toolbar.remove(expander_item);
			primary_toolbar.remove(refresh_button);
			primary_toolbar.remove(settings_button);
			//add them again
			setup_left_toolbar();
		}
	}

	private void save_geometry(){
		Allocation all;
		get_allocation(out all);
		int x, y;
		this.get_position(out x, out y);
		Settings.set_string("main-window-geometry", "%d,%d,%d,%d".printf(x, y,
						all.width, all.height));
	}

	private void load_geometry(){
		string geometry_str = Settings.get_string("main-window-geometry");
		string[] parts = geometry_str.split(",");
		int x = int.parse(parts[0]);
		int y = int.parse(parts[1]);
		int width = int.parse(parts[2]);
		int height = int.parse(parts[3]);
		this.move(x, y);
		this.resize(width, height);
	}
}
