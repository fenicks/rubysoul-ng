#!/usr/bin/ruby -w
=begin
  Made by Christian KAKESA etna_2008(paris) <christian.kakesa@gmail.com>

  TODO: implementer une function at_exit/deconnexion pour quitter proprement netsoul si on ferme l'aaplication'
=end

$KCODE = 'u'

begin
  require 'libglade2'
  require 'rs_config'
  require 'rs_contact'
  require 'rs_infobox'
rescue LoadError
  puts "Error: #{$!}"
  exit
end

class RubySoulNG
  include GetText

  attr :glade

  def initialize
    @connected = false
    @domain = RsConfig::APP_NAME
    bindtextdomain(@domain, nil, nil, "UTF-8")
    @glade = GladeXML.new(
    "#{RsConfig::APP_DIR+File::SEPARATOR}rubysoul-ng_win.glade",
    nil,
    @domain,
    nil,
    GladeXML::FILE) do |handler|
      method(handler)
    end
    @rsng_win = @glade['RubySoulNG']
    @rsng_user_view = @glade['user_view']
    @rsng_state_box = @glade['state_box']
    @contact_win = @glade['contact']
    @contact_add_entry = @glade['contact_add_entry']
    @contact_add_btn = @glade['contact_add_btn']
    @preferences_win = @glade['preferences']
    @preferences_nbook = @glade['prefs']
    @aboutdialog = @glade['aboutdialog']

    @rs_config = RsConfig::instance()
    @rs_contact = RsContact::instance()

    rsng_user_view_init()
    rsng_state_box_init()
    preferences_account_init()
  end
  #--- | Main window
  def on_RubySoulNG_delete_event(widget, event)
    Gtk.main_quit()
  end

  def on_tb_connect_clicked(widget)
    RsInfobox.new(@preferences_win, "[FUNCTION] on_tb_connect_clicked() not yet implemented", "warning")
  end
  def on_tb_contact_clicked(widget)
    @contact_win.show_all()
  end
  def on_tb_preferences_clicked(widget)
    preferences_account_load_config(@rs_config.conf)
    @preferences_win.show_all()
    @preferences_nbook.set_page(0)
  end
  def on_tb_about_clicked(widget)
    @aboutdialog.show_all()
    @aboutdialog.run()
    @aboutdialog.hide_all()
  end
  def rsng_user_view_init
    #--- | ICON_STATE, Login, PHOTO, {sublist} SessionNum, State, UserData
    @user_model = Gtk::TreeStore.new(Gdk::Pixbuf, String, Gdk::Pixbuf, String, String, String)
    @user_model.set_sort_column_id(1)
    @rsng_user_view.set_model(@user_model)
    renderer = Gtk::CellRendererPixbuf.new
    renderer.set_xalign(1.0)
    renderer.set_yalign(0.5)
    column = Gtk::TreeViewColumn.new("Status", renderer, :pixbuf => 0)
    @rsng_user_view.append_column(column)
    renderer = Gtk::CellRendererText.new
    renderer.set_alignment(Pango::ALIGN_LEFT)
    column = Gtk::TreeViewColumn.new("Login / Location", renderer, :markup => 1)
    @rsng_user_view.append_column(column)
    renderer = Gtk::CellRendererPixbuf.new
    renderer.set_xalign(1.0)
    renderer.set_yalign(0.5)
    column = Gtk::TreeViewColumn.new("Photo", renderer, :pixbuf => 2)
    @rsng_user_view.append_column(column)
    @rs_contact.contacts.each do |key, value|
      h = @user_model.append(nil)
      h.set_value(0, Gdk::Pixbuf.new(RsConfig::ICON_DISCONNECT, 24, 24))
      h.set_value(1, %Q[<span weight="bold" size="large">#{key.to_s}</span>])
      if (File.exist?(RsConfig::CONTACTS_PHOTO_DIR + key.to_s))
        h.set_value(2, Gdk::Pixbuf.new(RsConfig::CONTACTS_PHOTO_DIR + key.to_s, 32, 32))
      else
        h.set_value(2, Gdk::Pixbuf.new(RsConfig::CONTACTS_PHOTO_DIR + "login_l", 32, 32))
      end
      h.set_value(3, nil)
      h.set_value(4, nil)
      h.set_value(5, nil)
    end
    @rsng_user_view.signal_connect("row-activated") do |view, path, column|
      RsInfobox.new(@rsng_win, "@rsng_user_view.signal_connect(\"row-activated\") not yet implemented", "warning")
=begin
      if (ns.connected)
        get_user_dialog(ns, view.model.get_iter(path)[3], view.model.get_iter(path)[4], @photo_dir + view.model.get_iter(path)[3].to_s, view.model.get_iter(path)[5]).show_all
      else
        RsInfobox.new(@parent_win, "You are not connected. No dialog box available", "warning")
      end
=end
    end
  end
  def rsng_state_box_init
    model = Gtk::ListStore.new(String, Gdk::Pixbuf, String)
    @rsng_state_box.set_model(model)
    renderer = Gtk::CellRendererPixbuf.new
    @rsng_state_box.pack_start(renderer, false)
    @rsng_state_box.set_attributes(renderer, :pixbuf => 1)
    renderer = Gtk::CellRendererText.new
    @rsng_state_box.pack_end(renderer, true)
    @rsng_state_box.set_attributes(renderer, :text => 2)
    [["actif", Gdk::Pixbuf.new(RsConfig::ICON_STATE_ACTIVE, 24, 24), "Actif"],
    ["away", Gdk::Pixbuf.new(RsConfig::ICON_STATE_AWAY, 24, 24), "Away"],
    ["idle", Gdk::Pixbuf.new(RsConfig::ICON_STATE_IDLE, 24, 24), "Idle"],
    ["lock", Gdk::Pixbuf.new(RsConfig::ICON_STATE_LOCK, 24, 24), "Lock"]].each do |state, icon, name|
      iter = model.append()
      #iter[0] = state
      iter[1] = icon
      iter[2] = name
    end
    #--- | TODO: @rsng_state_box.sensitive = false
    @rsng_state_box.signal_connect("changed") do
      RsInfobox.new(@rsng_win, "[SIGNAL] @rsng_state_box.signal_connect(\"changed\") not yet implemented", "warning")
=begin
      if (@ns.connected)
        @ns.sock_send(NetSoul::Message.set_state(sb.active_iter[2], @ns.get_server_timestamp))
      end
=end
    end
  end

  #--- | Contacts window
  def on_contact_delete_event(widget, event)
    @contact_win.hide_all()
  end
  def on_contact_close_btn_clicked(widget)
    @contact_win.hide_all()
  end
  def on_contact_add_btn_clicked(widget)
    if @contact_add_entry.text.length > 0
      @rs_contact.add(@contact_add_entry.text, true)
      @contact_add_entry.text = ""
      #--- | TODO: If connected send whatch_log and who commands to netsoul server
    else
      RsInfobox.new(@contact_win, "No must specify the login", "warning")
    end
  end

  #--- | Preferences window
  def preferences_account_init
    @account_login_entry			= @glade['account_login_entry']
    @account_socks_password_entry		= @glade['account_socks_password_entry']
    @account_unix_password_entry		= @glade['account_unix_password_entry']
    @account_server_host_entry			= @glade['account_server_host_entry']
    @account_server_port_entry			= @glade['account_server_port_entry']
    @account_connection_type_md5		= @glade['account_connection_type_md5']
    @account_connection_type_krb5		= @glade['account_connection_type_krb5']
    @account_location_entry			= @glade['account_location_entry']
    @account_user_group_entry			= @glade['account_user_group_entry']
    @account_connection_at_startup_checkbox	= @glade['account_connection_at_startup_checkbox']
  end
  def preferences_account_load_config(conf)
    if conf[:login].to_s.length > 0
      @account_login_entry.text = conf[:login].to_s
    end
    if conf[:socks_password].to_s.length > 0
      @account_socks_password_entry.text = conf[:socks_password].to_s
    end
    if conf[:unix_password].to_s.length > 0
      @account_unix_password.text = conf[:unix_password].to_s
    end
    if conf[:server_host].to_s.length > 0
      @account_server_host_entry.text = conf[:server_host].to_s
    else
      @account_server_host_entry.text = conf[:server_host] = "ns-server.epita.fr"
    end
    if conf[:server_port].to_s.length > 0
      @account_server_port_entry.text = conf[:server_port].to_s
    else
      @account_server_port_entry.text = conf[:server_port] = "4242"
    end
    conf[:connection_type].eql?("krb5") ? @account_connection_type_krb5.set_active(true) : @account_connection_type_md5.set_active(true)
    if conf[:location].to_s.length > 0
      @account_location_entry.text = conf[:location].to_s
    end
    if conf[:user_group].to_s.length > 0
      @account_user_group_entry.text = conf[:user_group].to_s
    end
    conf[:connection_at_startup].eql?(true) ? @account_connection_at_startup_checkbox.set_active(true) : @account_connection_at_startup_checkbox.set_active(false)
  end
  def preferences_account_save_config
    @rs_config.conf[:login] = @account_login_entry.text if @account_login_entry.text.length > 0
    @rs_config.conf[:socks_password] = @account_socks_password_entry.text if @account_socks_password_entry.text.length > 0
    @rs_config.conf[:unix_password] = @account_unix_password_entry.text if @account_unix_password_entry.text.length > 0
    @rs_config.conf[:server_host] = @account_server_host_entry.text if @account_server_host_entry.text.length > 0
    @rs_config.conf[:server_port] = @account_server_port_entry.text if @account_server_port_entry.text.length > 0
    @rs_config.conf[:connection_type] = @account_connection_type_krb5.active?() ? "krb5" : "md5"
    @rs_config.conf[:location] = @account_location_entry.text if @account_location_entry.text.length > 0
    @rs_config.conf[:user_group] = @account_user_group_entry.text if @account_user_group_entry.text.length > 0
    @rs_config.conf[:connection_at_startup] = @account_connection_at_startup_checkbox.active?() ? true : false
    @rs_config.save()
  end
  def on_preferences_delete_event(widget, event)
    @preferences_win.hide_all()
  end
  def on_preferences_close_btn_clicked(widget)
    @preferences_win.hide_all()
  end
  def on_preferences_validate_btn_clicked(widget)
    preferences_account_save_config()
    @preferences_win.hide_all()
  end

  #--- | About window
end

### MAIN APPLICATION ###
########################
if __FILE__ == $0
  Gtk.init()
  RubySoulNG.new
  Gtk.main()
end

