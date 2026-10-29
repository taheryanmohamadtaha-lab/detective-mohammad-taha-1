extends Control
## Whole UI is built in code (RTL Persian). Case content comes from data/cases/*.json via the Game autoload.

const ACCENT := Color("e0a84f")
const TEXT := Color("f1ece1")
const MUTED := Color("9aa6b8")
const PANEL := Color(0.07, 0.10, 0.17, 0.90)
const BTN := Color(0.16, 0.22, 0.34, 1.0)
const BTN_ON := Color(0.55, 0.38, 0.12, 1.0)
const BTN_DARK := Color(0.10, 0.13, 0.20, 1.0)

const PH_PORTRAIT := "res://assets/characters/detective_dialogue.png"
const PH_NOIR := "res://assets/characters/detective_noir.png"
const PH_NPC := "res://assets/characters/npc.png"

var font: Font
var bg_rect: TextureRect
var header: Label
var scroll: ScrollContainer
var body: VBoxContainer
var footer: HBoxContainer

var cur_case: int = -1
var cur_tab: String = "places"
var cur_person: String = ""
var msg: String = ""
var _last_qa: Dictionary = {}
var _sel_a: int = 0
var _sel_b: int = 1
var _confirm_reset: bool = false
var _type_label: Label = null
var _type_tween: Tween = null


func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	_setup_theme()
	bg_rect = TextureRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_rect)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 18)
	margin.add_child(root_box)
	header = _label("", 54, ACCENT, true)
	root_box.add_child(header)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_box.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	scroll.add_child(body)
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	root_box.add_child(footer)
	if Game.cases.is_empty():
		header.text = "خطا: فایل‌های پرونده پیدا نشد"
		return
	show_menu()


# ---------------------------------------------------------------- helpers
func _setup_theme() -> void:
	var path := "res://assets/fonts/Vazirmatn-Regular.ttf"
	if ResourceLoader.exists(path):
		font = load(path)
	else:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Vazirmatn", "Noto Sans Arabic", "Noto Naskh Arabic", "Roboto", "sans-serif"])
		font = sf
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 34
	theme = th


func _label(t: String, size: int = 34, col: Color = TEXT, center: bool = false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text_direction = Control.TEXT_DIRECTION_RTL
	l.language = "fa"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_RIGHT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _on_btn(cb: Callable) -> void:
	Game.sfx("click")
	cb.call()


func _button(t: String, cb: Callable, col: Color = BTN, size: int = 34) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", size)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.text_direction = Control.TEXT_DIRECTION_RTL
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(14)
	b.add_theme_stylebox_override("normal", sb)
	var sh: StyleBoxFlat = sb.duplicate()
	sh.bg_color = col.lightened(0.15)
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	var sd: StyleBoxFlat = sb.duplicate()
	sd.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	b.add_theme_stylebox_override("disabled", sd)
	b.pressed.connect(_on_btn.bind(cb))
	return b


func _panel(col: Color = PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(24)
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _img(path: String, size: Vector2, cover: bool = false) -> TextureRect:
	var t := TextureRect.new()
	t.texture = _tex(path)
	t.custom_minimum_size = size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL if size.x == 0 else Control.SIZE_SHRINK_CENTER
	return t


func _set_bg(bg: String) -> void:
	bg_rect.texture = _tex("res://assets/backgrounds/%s.jpg" % bg)


func _clear() -> void:
	_type_label = null
	if _type_tween:
		_type_tween.kill()
		_type_tween = null
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	for c in footer.get_children():
		footer.remove_child(c)
		c.queue_free()
	scroll.set_deferred("scroll_vertical", 0)


func fa(n) -> String:
	var out := ""
	for ch in str(n):
		var d := "0123456789".find(ch)
		out += "۰۱۲۳۴۵۶۷۸۹"[d] if d >= 0 else ch
	return out


func _bubble(who: String, text: String, portrait: String, col: Color, typewriter: bool = false) -> PanelContainer:
	var pan := _panel(col)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	pan.add_child(h)
	h.add_child(_img(portrait, Vector2(150, 150)))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(_label(who, 30, ACCENT))
	var l := _label(text, int(Game.state["settings"]["font_size"]))
	v.add_child(l)
	if typewriter:
		_type_label = l
	return pan


func _start_type() -> void:
	if _type_label == null:
		return
	var l := _type_label
	l.visible_ratio = 0.0
	var dur := maxf(0.3, float(l.text.length()) / float(Game.state["settings"]["text_speed"]))
	_type_tween = l.create_tween()
	_type_tween.tween_property(l, "visible_ratio", 1.0, dur)


func _skip_type() -> void:
	if _type_tween:
		_type_tween.kill()
	if _type_label and is_instance_valid(_type_label):
		_type_label.visible_ratio = 1.0


# ---------------------------------------------------------------- menu & lists
func show_menu() -> void:
	cur_case = -1
	_clear()
	_set_bg("office")
	header.text = ""
	body.add_child(_img(PH_NOIR, Vector2(520, 520)))
	body.add_child(_label("پرونده‌های کارآگاه محمدطاها", 62, ACCENT, true))
	body.add_child(_label("Detective Mohammad Taha", 30, MUTED, true))
	if Game.has_progress():
		body.add_child(_button("ادامه بازی", _continue_game, BTN_ON))
		body.add_child(_button("شروع تازه‌ی بازی" if not _confirm_reset else "مطمئنی؟ پیشرفت پاک می‌شود. دوباره لمس کن", _new_game))
	else:
		body.add_child(_button("شروع بازی", _new_game, BTN_ON))
	body.add_child(_button("انتخاب پرونده", show_cases))
	body.add_child(_button("تنظیمات", show_settings))
	body.add_child(_button("درباره‌ی بازی", show_about))


func _continue_game() -> void:
	open_case(Game.first_unfinished())


func _new_game() -> void:
	if Game.has_progress() and not _confirm_reset:
		_confirm_reset = true
		show_menu()
		return
	_confirm_reset = false
	Game.reset_progress()
	open_case(0)


func show_cases() -> void:
	cur_case = -1
	_confirm_reset = false
	_clear()
	_set_bg("office")
	header.text = "انتخاب پرونده"
	for i in Game.cases.size():
		var c: Dictionary = Game.cases[i]
		var unlocked: bool = i < int(Game.state["unlocked"])
		var t: String = "%s. %s" % [fa(i + 1), c["title"]]
		if Game.state["scores"].has(c["id"]):
			t += "   ✓ امتیاز " + fa(Game.state["scores"][c["id"]])
		elif not unlocked:
			t += "   (قفل — پرونده‌ی قبلی را حل کن)"
		var b := _button(t, open_case.bind(i), BTN_ON if (unlocked and not Game.prog(i)["done"]) else BTN)
		b.disabled = not unlocked
		body.add_child(b)
	body.add_child(_button("بازگشت", show_menu, BTN_DARK))


func _set_setting(key: String, val) -> void:
	Game.state["settings"][key] = val
	Game.save()
	show_settings()


func _choice_row(title: String, options: Array, key: String) -> void:
	body.add_child(_label(title, 34, ACCENT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for o in options:
		var sel: bool = Game.state["settings"][key] == o[1]
		row.add_child(_button(o[0], _set_setting.bind(key, o[1]), BTN_ON if sel else BTN, 30))
	body.add_child(row)


func _on_music(v: float) -> void:
	Game.set_music_volume(v)
	Game.save()


func _on_voice_vol(v: float) -> void:
	Game.state["settings"]["voice_vol"] = v
	Game.save()


func _slider(title: String, val: float, cb: Callable) -> void:
	body.add_child(_label(title, 34, ACCENT))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = val
	s.custom_minimum_size = Vector2(0, 60)
	s.value_changed.connect(cb)
	body.add_child(s)


func show_settings() -> void:
	_clear()
	_set_bg("interrogation")
	header.text = "تنظیمات"
	_slider("صدای موسیقی و محیط", float(Game.state["settings"]["music"]), _on_music)
	_slider("صدای گفت‌وگو", float(Game.state["settings"]["voice_vol"]), _on_voice_vol)
	_choice_row("صدای گفت‌وگو (گوینده‌ی فارسی)", [["روشن", true], ["خاموش", false]], "voice")
	if Game.has_voice():
		body.add_child(_label("گوینده‌ی فارسی در این دستگاه موجود است.", 28, MUTED))
	else:
		body.add_child(_label("گوینده‌ی فارسی در این دستگاه پیدا نشد؛ فقط زیرنویس نمایش داده می‌شود و بازی بدون صدا کاملاً قابل انجام است.", 28, MUTED))
	_choice_row("لرزش", [["روشن", true], ["خاموش", false]], "vibrate")
	_choice_row("اندازه‌ی زیرنویس", [["کوچک", 28], ["متوسط", 34], ["بزرگ", 42]], "font_size")
	_choice_row("سرعت نمایش متن", [["کند", 25], ["متوسط", 45], ["سریع", 90]], "text_speed")
	_choice_row("بیشترین سطح راهنما", [["هیچ", 0], ["کم", 1], ["متوسط", 2], ["کامل", 3]], "max_hint")
	body.add_child(_button("بازگشت", show_menu, BTN_DARK))


func show_about() -> void:
	_clear()
	_set_bg("lab")
	header.text = "درباره‌ی بازی"
	var pan := _panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pan.add_child(v)
	v.add_child(_img(PH_NOIR, Vector2(300, 300)))
	v.add_child(_label("پرونده‌های کارآگاه محمدطاها\nقهرمان بازی: کارآگاه محمدطاها طاهریان.\nهشت پرونده‌ی مستقل با یک داستان پیوسته. بازی کاملاً آفلاین است و پیشرفت روی خود دستگاه ذخیره می‌شود.", 32))
	v.add_child(_label("فونت: Vazirmatn (مجوز SIL OFL). موسیقی و جلوه‌های صوتی این نسخه به‌صورت برنامه‌ای تولید شده‌اند. نسخه‌ی ۱٫۰", 26, MUTED))
	body.add_child(pan)
	body.add_child(_button("بازگشت", show_menu, BTN_DARK))


# ---------------------------------------------------------------- case flow
func open_case(i: int) -> void:
	cur_case = i
	cur_person = ""
	_last_qa.clear()
	_sel_a = 0
	_sel_b = 1
	msg = ""
	var p := Game.prog(i)
	cur_tab = "places"
	if not p["started"]:
		_show_intro()
	else:
		render_case()


func _show_intro() -> void:
	var c: Dictionary = Game.cases[cur_case]
	_clear()
	_set_bg(c["bg"])
	header.text = "%s. %s" % [fa(cur_case + 1), c["title"]]
	body.add_child(_bubble("کارآگاه محمدطاها", c["intro"], PH_PORTRAIT, Color(0.12, 0.22, 0.36, 0.95)))
	body.add_child(_button("شروع تحقیق", _begin_case, BTN_ON))
	body.add_child(_button("بازگشت به فهرست", show_cases, BTN_DARK))
	Game.speak(c["intro"])


func _begin_case() -> void:
	Game.prog(cur_case)["started"] = true
	Game.save()
	Game.stop_speech()
	render_case()


func _tab(id: String) -> void:
	cur_tab = id
	cur_person = ""
	Game.stop_speech()
	render_case()


func _build_footer() -> void:
	var tabs := [["places", "مکان‌ها"], ["people", "افراد"], ["notes", "دفترچه"], ["hint", "راهنما"], ["accuse", "اتهام"]]
	for t in tabs:
		footer.add_child(_button(t[1], _tab.bind(t[0]), BTN_ON if cur_tab == t[0] else BTN, 26))
	footer.add_child(_button("فهرست", show_cases, BTN_DARK, 26))


func render_case() -> void:
	var c: Dictionary = Game.cases[cur_case]
	var p := Game.prog(cur_case)
	_clear()
	_set_bg(c["bg"])
	header.text = c["title"]
	_build_footer()
	if msg != "":
		var mp := _panel(Color(0.35, 0.25, 0.08, 0.95))
		mp.add_child(_label(msg, 32))
		body.add_child(mp)
		msg = ""
	match cur_tab:
		"places":
			_tab_places(c, p)
		"people":
			_tab_people(c, p)
		"notes":
			_tab_notes(c, p)
		"hint":
			_tab_hint(c, p)
		"accuse":
			_tab_accuse(c, p)
	_start_type()


# ---- places
func _tab_places(c: Dictionary, p: Dictionary) -> void:
	for pl in c["places"]:
		var pan := _panel()
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 12)
		pan.add_child(v)
		v.add_child(_img("res://assets/backgrounds/%s.jpg" % pl["bg"], Vector2(0, 220), true))
		v.add_child(_label(pl["name"], 40, ACCENT))
		for it in pl["items"]:
			var seen: bool = p["seen"].has(it["name"])
			v.add_child(_button(it["name"] + ("   ✓" if seen else ""), _examine.bind(it)))
		body.add_child(pan)


func _examine(it: Dictionary) -> void:
	var c: Dictionary = Game.cases[cur_case]
	var p := Game.prog(cur_case)
	if not p["seen"].has(it["name"]):
		p["seen"].append(it["name"])
	msg = it["text"]
	if it["ev"] != "" and Game.add_evidence(cur_case, it["ev"]):
		msg += "\n\nمدرک جدید به دفترچه اضافه شد: «%s»" % c["evidence"][it["ev"]]["name"]
		Game.sfx("found")
		Game.vibrate()
	Game.save()
	render_case()


# ---- people & dialogue
func _pick_person(pid: String) -> void:
	cur_person = pid
	render_case()


func _back_people() -> void:
	cur_person = ""
	Game.stop_speech()
	render_case()


func _tab_people(c: Dictionary, p: Dictionary) -> void:
	if cur_person == "":
		body.add_child(_label("با چه کسی صحبت می‌کنی؟", 38, ACCENT))
		for pp in c["people"]:
			body.add_child(_button("%s — %s" % [pp["name"], pp["role"]], _pick_person.bind(pp["id"])))
		return
	var pe := Game.person(cur_case, cur_person)
	body.add_child(_button("‹ بازگشت به فهرست افراد", _back_people, BTN_DARK))
	var last: int = int(_last_qa.get(cur_person, -1))
	if last >= 0:
		var q: Dictionary = pe["asks"][last]
		body.add_child(_bubble("کارآگاه محمدطاها", q["q"], PH_PORTRAIT, Color(0.12, 0.22, 0.36, 0.95)))
		body.add_child(_bubble(pe["name"], q["a"], PH_NPC, Color(0.22, 0.16, 0.10, 0.95), true))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(_button("پخش مجدد صدا", Game.speak.bind(q["a"]), BTN, 26))
		row.add_child(_button("توقف صدا", Game.stop_speech, BTN, 26))
		row.add_child(_button("رد کردن", _skip_type, BTN, 26))
		body.add_child(row)
	else:
		body.add_child(_bubble(pe["name"], pe["intro"], PH_NPC, Color(0.22, 0.16, 0.10, 0.95)))
	body.add_child(_label("سؤال خودت را انتخاب کن:", 32, ACCENT))
	for i in pe["asks"].size():
		var q: Dictionary = pe["asks"][i]
		var locked: bool = q["need"] != "" and not p["ev"].has(q["need"])
		var asked: bool = p["seen"].has("q:%s:%d" % [pe["id"], i])
		var label: String = q["q"] + ("   ✓" if asked else "")
		if locked:
			label = "این گزینه قفل است؛ اول باید مدرک مرتبط را پیدا کنی."
		var b := _button(label, _ask.bind(pe["id"], i))
		b.disabled = locked
		body.add_child(b)


func _ask(pid: String, qi: int) -> void:
	var c: Dictionary = Game.cases[cur_case]
	var p := Game.prog(cur_case)
	var pe := Game.person(cur_case, pid)
	var q: Dictionary = pe["asks"][qi]
	_last_qa[pid] = qi
	var key: String = "q:%s:%d" % [pid, qi]
	if not p["seen"].has(key):
		p["seen"].append(key)
	if q["ev"] != "" and Game.add_evidence(cur_case, q["ev"]):
		msg = "مدرک جدید به دفترچه اضافه شد: «%s»" % c["evidence"][q["ev"]]["name"]
		Game.sfx("found")
		Game.vibrate()
	Game.speak(q["a"])
	Game.save()
	render_case()


# ---- notebook & clue board
func _toggle_checked(eid: String) -> void:
	var p := Game.prog(cur_case)
	var k: String = "e:" + eid
	if p["checked"].has(k):
		p["checked"].erase(k)
	else:
		p["checked"].append(k)
	Game.save()
	render_case()


func _on_sel_a(i: int) -> void:
	_sel_a = i


func _on_sel_b(i: int) -> void:
	_sel_b = i


func _make_picker(c: Dictionary, p: Dictionary, sel: int, cb: Callable) -> OptionButton:
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(0, 90)
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ob.text_direction = Control.TEXT_DIRECTION_RTL
	ob.add_theme_font_size_override("font_size", 28)
	ob.get_popup().add_theme_font_size_override("font_size", 30)
	for eid in p["ev"]:
		ob.add_item(c["evidence"][eid]["name"])
	ob.selected = clampi(sel, 0, p["ev"].size() - 1)
	ob.item_selected.connect(cb)
	return ob


func _tab_notes(c: Dictionary, p: Dictionary) -> void:
	body.add_child(_label("دفترچه‌ی شواهد (%s از %s)" % [fa(p["ev"].size()), fa(c["evidence"].size())], 40, ACCENT))
	if p["ev"].is_empty():
		body.add_child(_label("هنوز مدرکی پیدا نکرده‌ای. به مکان‌ها سر بزن و با افراد صحبت کن.", 32, MUTED))
		return
	for eid in p["ev"]:
		var e: Dictionary = c["evidence"][eid]
		var pan := _panel()
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		pan.add_child(v)
		v.add_child(_label(e["name"], 36, ACCENT))
		v.add_child(_label(e["text"], 32))
		v.add_child(_label("محل کشف: " + e["where"], 26, MUTED))
		var done: bool = p["checked"].has("e:" + eid)
		v.add_child(_button("بررسی‌شده ✓" if done else "علامت‌گذاری به‌عنوان بررسی‌شده", _toggle_checked.bind(eid), BTN_ON if done else BTN, 28))
		body.add_child(pan)
	if p["ev"].size() >= 2:
		body.add_child(_label("تخته‌ی ارتباط سرنخ‌ها", 40, ACCENT))
		body.add_child(_label("دو مدرک را انتخاب کن که با هم نمی‌خوانند یا یکدیگر را تأیید می‌کنند.", 28, MUTED))
		body.add_child(_make_picker(c, p, _sel_a, _on_sel_a))
		body.add_child(_make_picker(c, p, _sel_b, _on_sel_b))
		body.add_child(_button("تطبیق مدارک", _try_link, BTN_ON))
	body.add_child(_label("ارتباط‌های کشف‌شده (%s از %s)" % [fa(p["links"].size()), fa(c["links"].size())], 34, ACCENT))
	for idx in p["links"]:
		var L: Dictionary = c["links"][idx]
		var pan2 := _panel(Color(0.10, 0.20, 0.16, 0.92))
		pan2.add_child(_label("%s  ⟷  %s\n%s" % [c["evidence"][L["a"]]["name"], c["evidence"][L["b"]]["name"], L["text"]], 30))
		body.add_child(pan2)


func _try_link() -> void:
	var c: Dictionary = Game.cases[cur_case]
	var p := Game.prog(cur_case)
	if p["ev"].size() < 2:
		return
	var a: String = p["ev"][clampi(_sel_a, 0, p["ev"].size() - 1)]
	var b: String = p["ev"][clampi(_sel_b, 0, p["ev"].size() - 1)]
	if a == b:
		msg = "دو مدرک متفاوت انتخاب کن."
		render_case()
		return
	for i in c["links"].size():
		var L: Dictionary = c["links"][i]
		if (L["a"] == a and L["b"] == b) or (L["a"] == b and L["b"] == a):
			if p["links"].has(i):
				msg = "این ارتباط را قبلاً کشف کرده‌ای."
			else:
				p["links"].append(i)
				msg = "آفرین! متوجه شدی. " + L["text"]
				Game.sfx("found")
				Game.vibrate(80)
				Game.speak(L["text"])
			Game.save()
			render_case()
			return
	Game.sfx("wrong")
	msg = c.get("wrong_link", "ارتباطی پیدا نشد.")
	render_case()


# ---- hints
func _use_hint(lvl: int) -> void:
	var p := Game.prog(cur_case)
	if lvl == int(p["hints"]) + 1:
		p["hints"] = lvl
		Game.save()
	render_case()


func _tab_hint(c: Dictionary, p: Dictionary) -> void:
	var names := ["اشاره‌ی کوتاه", "راهنمایی متوسط", "راهنمایی کامل (آخرین گزینه)"]
	var maxh: int = int(Game.state["settings"]["max_hint"])
	body.add_child(_label("راهنمایی از امتیاز پرونده کم می‌کند. اول اشاره‌ی کوتاه را امتحان کن.", 30, MUTED))
	for lvl in range(1, 4):
		if lvl <= int(p["hints"]):
			var pan := _panel(Color(0.20, 0.18, 0.08, 0.95))
			var v := VBoxContainer.new()
			pan.add_child(v)
			v.add_child(_label(names[lvl - 1], 34, ACCENT))
			v.add_child(_label(c["hints"][lvl - 1], int(Game.state["settings"]["font_size"])))
			body.add_child(pan)
		else:
			var b := _button("نمایش " + names[lvl - 1], _use_hint.bind(lvl))
			b.disabled = lvl > int(p["hints"]) + 1 or lvl > maxh
			body.add_child(b)
	if maxh < 3:
		body.add_child(_label("سقف راهنما در تنظیمات روی سطح %s است." % fa(maxh), 26, MUTED))


# ---- accusation
func _tab_accuse(c: Dictionary, p: Dictionary) -> void:
	body.add_child(_label("انتخاب مظنون", 40, ACCENT))
	body.add_child(_label("ارتباط‌های کشف‌شده: %s از %s. بدون اثبات کافی نمی‌توانی پرونده را ببندی." % [fa(p["links"].size()), fa(c["links"].size())], 30, MUTED))
	for pe in c["people"]:
		body.add_child(_button("%s — %s" % [pe["name"], pe["role"]], _accuse.bind(pe["id"])))


func _accuse(pid: String) -> void:
	var c: Dictionary = Game.cases[cur_case]
	var p := Game.prog(cur_case)
	var pe := Game.person(cur_case, pid)
	if pid == c["culprit"]:
		if p["links"].size() >= c["links"].size():
			_finish_case()
			return
		var missing: int = c["links"].size() - p["links"].size()
		msg = "حدست درست به نظر می‌رسد، اما هنوز %s ارتباط کلیدی را ثابت نکرده‌ای. با مدارک ناقص نمی‌شود کسی را محکوم کرد؛ دفترچه و تخته‌ی ارتباط را دوباره ببین." % fa(missing)
		Game.sfx("click")
	else:
		p["wrong"] = int(p["wrong"]) + 1
		msg = pe["defense"]
		Game.sfx("wrong")
	Game.save()
	render_case()


func _score(c: Dictionary, p: Dictionary) -> int:
	return maxi(0, 500 + 100 * p["ev"].size() + 300 * p["links"].size() - 150 * int(p["hints"]) - 100 * int(p["wrong"]))


func _finish_case() -> void:
	var c: Dictionary = Game.cases[cur_case]
	var p := Game.prog(cur_case)
	var score := _score(c, p)
	Game.complete(cur_case, score)
	Game.sfx("found")
	Game.vibrate(120)
	var maxs: float = 500.0 + 100.0 * c["evidence"].size() + 300.0 * c["links"].size()
	var ratio: float = float(score) / maxs
	var stars := 3 if ratio >= 0.85 else (2 if ratio >= 0.6 else 1)
	_clear()
	_set_bg(c["bg"])
	header.text = "پرونده حل شد!"
	body.add_child(_img(PH_NOIR, Vector2(380, 380)))
	body.add_child(_bubble("کارآگاه محمدطاها", c["win"], PH_PORTRAIT, Color(0.12, 0.22, 0.36, 0.95)))
	var sp := _panel()
	var v := VBoxContainer.new()
	sp.add_child(v)
	v.add_child(_label("امتیاز: %s   |   ستاره: %s از ۳" % [fa(score), fa(stars)], 38, ACCENT, true))
	v.add_child(_label("مدارک: %s   |   ارتباط‌ها: %s   |   راهنما: %s   |   اشتباه: %s" % [fa(p["ev"].size()), fa(p["links"].size()), fa(p["hints"]), fa(p["wrong"])], 26, MUTED, true))
	body.add_child(sp)
	Game.speak(c["win"])
	if cur_case + 1 < Game.cases.size():
		body.add_child(_button("پرونده‌ی بعدی", open_case.bind(cur_case + 1), BTN_ON))
	else:
		var ep := _panel(Color(0.22, 0.16, 0.06, 0.95))
		ep.add_child(_label("پایان بزرگ‌ترین پرونده. شهر امن‌تر است، و کارآگاه محمدطاها از فردا منتظر معمای بعدی است.", 34, TEXT, true))
		body.add_child(ep)
	body.add_child(_button("فهرست پرونده‌ها", show_cases))
	body.add_child(_button("منوی اصلی", show_menu, BTN_DARK))
