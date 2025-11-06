-- How to translate
-- ----------------
-- Translate each text string to the target language leaving intact the two
-- double quotes.
-- Example: "Log In" should become "Entrar"
--
-- If you need to use a double quote, escape it with a backslash (\")
--
-- The "@" symbol followed by a number represents a parameter that the system
-- will substitute by a value, for example a username.
-- Example: "Welcome, @1!" will become "Welcome, Mary!" when Mary is logged in.
--
-- You need to leave "@" marks intact, but you can change their order in your
-- translation if your language requires so.

local locale = {

    -- Meta data
    -- =========
    lang_name = "简体中文",
    lang_code = "zh",
    authors = "Simon Mong, 18001767679, moodykeke@gmail.com",
    last_updated = "2022/08/11", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "运行 Snap@1", -- @1 becomes an italic exclamation mark (!)
    explore = "作品合集",
    forum = "论坛",
    join = "注册",
    login = "登录",
    -- User menu
    my_projects = "我的作品",
    my_collections = "我的作品集",
    my_public_page = "我的展示",
    my_profile = "我的个人主页",
    administration = "管理页面",
    followed_projects = "我关注的项目",
    bookmarked_projects = "我收藏的项目",
    logout = "退出登录",
    Learn = "学习",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "",

    -- Footer
    -- ======
    -- Titles
    t_about = "关于",
    t_learning = "学习",
    t_tools = "工具",
    t_support = "支持",
    t_legal = "合法的",
    -- Links
    about = "关于Snap@1",
    blog = "博客",
    credits = "制作人员名单",
    requirements = "技术需求",
    partners = "合作伙伴",
    source = "源代码",
    events = " 活动",
    examples = "示例",
    manual = "参考手册",
    materials = "素材",
    bjc = "BJC课程",
    research = "探索",
    offline = "离线版本",
    extensions = "模块/包",
    old_snap = "旧版 Snap",
    -- forum already translated in top navigation bar
    contact = "联系我们",
    mirrors = "镜像",
    dmca = "DMCA",
    privacy = "隐私",
    tos = "服务条款",

    -- Index page
    -- ==========
    welcome = "欢迎使用Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "欢迎回来，@1", -- @1 becomes the current user username
    snap_description = "Snap@1是一种对儿童和成人具有广泛吸引力的编程语言，同时也是重要的计算机科学学习平台。",
    -- Buttons
    run_now = "运行 @1",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "精选项目",
    totm = "本月主题", -- @1 becomes the actual topic of the month
    science = "科学作品",
    simulations = "模拟作品",
    three_d = "3D作品",
    music = "音乐作品",
    art = "艺术作品",
    fractals = "分形艺术作品",
    animations = "动画作品",
    games = "游戏作品",
    cs = "计算机科学",
    maths = "数学",
    latest = "最新项目",
    more_collections = "更多作品集",

    -- Events page
    events_title = "活动",

    -- Collections page
    collections_title = "作品集",

    -- User Collections page
    user_collections_title = "我的作品集",

    -- User Projects page
    user_projects_title = "我的作品",

    -- Sign up page
    -- ============
    signup_title = "创建 Snap@1 账号", -- @1 becomes an italic exclamation mark (!)
    username = "用户名称",
    password = "密码",
    password_2 = "再次输入密码",
    birth_month = "出生月份",
    or_before = "或者之前", -- is preceded by a year, like "1995 or before"
    email_parent = "父母或监护人的邮件地址",
    email_user = "邮件地址",
    email_2 = "再次输入邮件地址",
    tos_agree = "", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "隐私协议",
    signup = "注册",

    -- Log in page
    -- ===========
    log_into_snap = "登录到Snap@1", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "保持登录状态",
    i_forgot_password = "忘记密码",
    i_forgot_username = "忘记用户名",

    -- Dates
    -- =====
    -- Month names
    january = "一月",
    february = "二月",
    march = "三月",
    april = "四月",
    may = "五月",
    june = "六月",
    july = "七月",
    august = "八月",
    september = "九月",
    october = "十月",
    november = "十一月",
    december = "十二月",
    -- Date format
    date = "@1 @2 @3", -- @1 is the day, @2 is the month name, @3 is the year

    -- Generic dialogs
    -- ===============
    ok = "确定",
    cancel = "取消",
    confirm = "确认",

    -- Explore page
    -- ============
    published_projects = "已发布项目",
    published_collections = "已发布作品集",

    -- Learn Snap! Page
    -- ==============
    learn_snap = "学习 @1", -- @1 becomes Snap!

    -- Search results page
    -- ===================
    search_results = "搜索结果",
    project_search_results = "项目搜索结果",
    collection_search_results = "作品集搜索结果",
    user_search_results = "用户搜索结果",
    projects = "项目",
    collections = "作品集",
    users = "用户",

    -- Users page
    -- ==========
    last_users = "最近的用户",

    -- Search component in grids
    -- =========================
    matching = "匹配", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "新的作品集",
    -- New collection dialog
    collection_name = "作品集名称",
    collection_by_thumb = "作者: @1", -- @1 is the author's username
    -- Collection page
    -- ===============
    collection_by = "作者: @1", -- @1 is the author's username
    -- Dates
    collection_created_date = "创建日期: @1",
    collection_updated_date = "更新日期: @1",
    collection_shared_date = "分享日期: @1",
    collection_published_date = "发布日期: @1",
    -- Buttons
    share_collection_button = "分享",
    unshare_collection_button = "取消分享",
    publish_collection_button = "发布",
    unpublish_collection_button = "取消发布",
    delete_collection_button = "删除",
    make_ffa = "免费访问",
    unmake_ffa = "取消免费访问",
    unenroll = "取消注册",
    -- Project Thumbnail
    project_by_thumb = "作者: @1", -- @1 is the author's username
    item_shared_info = "已分享",
    item_not_shared_info = "未分享",
    item_published_info = "已发布",
    item_not_published_info = "未发布",
    confirm_uncollect = "确认从作品集中移除？", -- @1 becomes a new line. You can add as many as you need.
    remove_from_collection_tooltip = "从作品集中移除",
    collection_thumbnail_tooltip = "点击以查看作品集",

    -- Collection dialogs
    -- ==================
    confirm_share_collection = "确认要分享这个作品集吗？",
    confirm_unshare_collection = "确认要取消分享这个作品集吗？",
    confirm_publish_collection = "确认要发布这个作品集吗？",
    confirm_unpublish_collection = "确认要取消发布这个作品集吗？",
    confirm_ffa = "确认要设置为免费访问吗？", -- @1 becomes a new line. You can add as many as you need.
    confirm_unffa = "确认要取消免费访问吗？", -- @1 becomes a new line. You can add as many as you need.
    confirm_unenroll = "",

    -- Followed users feed
    -- ===================
    followed_feed = "我关注的用户的项目",
    following_nobody = "您还没有关注任何用户。访问用户的公开页面并点击 @1 以关注他们，然后在此页面查看他们最新的公开项目。",
    followed_users = "您关注的用户",
    follower_users = "关注您的用户",

    -- Bookmarked projects feed
    -- ========================
    bookmarked_feed = "我收藏的项目",
    no_bookmarks = "您还没有收藏任何项目。点击您喜欢的项目下方的心形图标以收藏它。",
    recent_bookmarks = "最近收藏的项目",

    -- User public page
    -- ================================
    public_page = "用户页面: @1", -- @1 becomes the user's username
    -- Admin tools
    admin_tools = "管理工具",
    latest_published_projects = "最新发布的项目",
    latest_published_collections = "最新发布的作品集",

    -- User profile
    -- ============
    profile_title = "用户资料: @1", -- @1 becomes the user's username
    join_date = "加入日期", -- date of user creation follows
    email = "邮箱",
    role = "角色",
    -- User roles
    standard = "标准的",
    reviewer = "浏览者",
    moderator = "版主",
    admin = "管理员",
    banned = "被封禁",
    -- Buttons
    change_my_password = "更改密码",
    change_my_email = "更改我的邮箱",
    delete_my_user = "删除我的账号",

    -- Project page
    -- ============
    remixed_from = "从 @1 (作者: @2) 混合而来", -- @1 is the original project name, @2 is its author's username
    project_by = "作者: @1", -- @1 is the username
    project_remixes_title = "项目混合",
    project_collections_title = "项目作品集",
    shift_enter_note = "按 Shift+Enter 换行", -- in the notes field
    no_notes = "这个项目没有说明",
    created_date = "创建日期",
    updated_date = "更新日期",
    shared_date = "分享日期",
    published_date = "发布日期",
    -- Buttons
    see_code = "查看代码",
    edit = "编辑",
    download = "下载",
    embed = "嵌入",
    collect = "添加至作品集",
    delete_button = "删除",
    publish_button = "发布",
    share_button = "分享",
    unpublish_button = "取消发布",
    unshare_button = "取消分享",
    -- Flagging
    you_flagged = "您已举报此项目",
    unflag_project = "取消举报",
    flag_project = "举报",

    -- Embed dialog
    -- ============
    embed_title = "嵌入选项",
    embed_explanation = "请选择您想在嵌入式项目浏览器中包含的组件:",
    project_title = "项目标题",
    project_author = "项目作者",
    edit_button = "编辑按钮",
    pause_button = "暂停按钮",
    embed_url = "嵌入链接",
    embed_code = "嵌入代码",

    -- Collect dialog
    -- ==============
    collect_title = "添加至作品集",
    collect_explanation = "请选择您想添加到的作品集:",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "确认要删除这个项目么？",
    confirm_delete_user = "确认要删除这个用户么？",
    confirm_delete_collection = "确认要删除这个作品集么？",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "确认要分享这个项目么？",
    confirm_unshare_project = "确认要取消分享这个项目么？",
    confirm_publish_project = "确认要发布这个项目么？",
    confirm_unpublish_project = "确认要取消发布这个项目么？",

    -- Flag project dialogs
    -- ====================
    flag_prewarning = "", -- @1 becomes a new line. You can add as many as you need.
    choose_flag_reason = "选择举报原因",
    flag_reason_hack = "恶意修改",
    flag_reason_coc = "违反社区准则",
    flag_reason_dmca = "侵犯版权",
    flag_reason_notes = "其他原因",
    flag_reason_notes_placeholder = "请输入其他原因",

    -- User admin component
    -- ====================
    user_id = "用户ID",
    project_count = "项目数量",
    -- Buttons
    become = "成为", -- as an admin, temporarily impersonate this user
    change_email = "更改邮箱",
    send_msg = "",
    ban = "封禁",
    unban = "",
    delete_usr = "删除",
    -- New email dialog
    new_email = "新邮箱地址",
    -- Send message dialog
    compose_email = "撰写邮件",
    msg_subject = "邮件主题",
    msg_body = "邮件正文",
    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "确认要删除这个用户么？",
    warning_no_return = "注意！这个操作无法被撤销！",

    -- Change password page
    -- ====================
    change_password_title = "更改您的密码",
    current_pwd = "当前密码",
    new_pwd = "设置新密码",
    new_pwd_2 = "再次输入新密码",

    -- Change email page
    -- =================
    new_email_2 = "再次输入新的邮件地址",

    -- Administration page
    -- ===================
    carousel_admin = "轮播管理",
    user_admin = "用户管理",
    zombie_admin = "僵尸项目管理",
    flagged_projects = "被举报的项目",
    suspicious_ips = "可疑IP地址",
    -- user page
    -- ===================    
    follow_user = "关注用户",

    -- Error messages
    -- ==============
    err_login_failed = "登录失败",
    err_password_mismatch = "密码不匹配", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "密码不匹配",
    err_email_mismatch = "邮箱不匹配", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "邮箱不匹配",

    -- Auto-generated
    partials_alt_snap_wide_walls = "Snap! - Wide Walls",
    users_placeholder_password = "密码",
    partials_alt_snap_low_floor_showing_flowers = "Snap! - Low Floor (showing flowers)",
    static_alt_citilab_logo = "CitiLab Logo",
    static_alt_faber_residency_logo = "Faber Residency Logo",
    static_alt_sap_logo = "SAP Logo",
    static_alt_a_snap_list_contains_blocks_including_vee = "A Snap! list contains blocks (including vee)",
    static_alt_beetle_blocks_logo = "Beetle Blocks logo",
    static_alt_nsf_logo = "NSF Logo",
    static_title_snap_source_code = "Snap! Source Code",
    static_alt_edc_logo = "EDC Logo",
    static_alt_snap4arduino_logo = "Snap4Arduino Logo",
    partials_alt_collection_thumbnail = "collection thumbnail",
    partials_alt_snap_no_ceiling = "Snap! - No Ceiling",
    admin_title_front_page = "首页",
    static_alt_implementation_of_the_for_block_in_snap = "implementation of the for block in Snap!",
    static_alt_snap = "Snap!",
    static_alt_microsoft_teals_logo = "Microsoft TEALS logo",
    partials_title_this_item_is_itempublished_and = "This item is <%= item.published and",
    partials_placeholder_search = "搜索",
    embed_title_see_source_code = "See source code",
    partials_title_this_item_itemshared_and = "This item <%= item.shared and",
    layout_alt_uc_berkeley_logo = "UC Berkeley Logo",
    admin_title_events = "活动",
    static_alt_miosoft_logo = "Miosoft Logo",
    index_alt_snap = "Snap!",
    layout_placeholder_search = "搜索",
    static_alt_turtlestitch_logo = "TurtleStitch Logo",
    static_alt_microblocks_logo = "microblocks logo",
    admin_title_examples = "示例",
    partials_alt_view_topic_of_the_month = "View Topic of the Month",
    static_alt_bjc_logo = "BJC Logo",
    partials_placeholder_username = "用户名",
    static_title_snap_online = "Snap! online",
    sessions_placeholder_email_address = "Email address",
    partials_alt_snap_build_your_own_blocks = "Snap! - Build Your Own Blocks",
    project_title_project_viewer = "project viewer",
    layout_alt_sap_logo = "SAP Logo",
    
    -- Admin TOTM page
    -- ===============
    admin_totm_title = "当前月度主题",
    admin_totm_banner = "横幅图片",
    admin_totm_collection = "作品集",
    admin_totm_choose_file = "选择文件",
    admin_totm_upload_banner = "上传横幅",
    admin_totm_success = "月度主题更新成功！",
    admin_totm_error = "月度主题更新失败",
    admin_totm_current_banner = "当前激活的横幅",
    admin_totm_uploaded = "上传于",
    admin_totm_no_active_banner = "未设置激活的横幅。请上传并选择一个。",
    admin_totm_upload_new = "上传新横幅",
    admin_totm_banner_library = "横幅库",
    admin_totm_active = "已激活",
    admin_totm_select = "选择",
    admin_totm_delete = "删除",
    admin_totm_confirm_select = "将此横幅设为激活状态？",
    admin_totm_confirm_delete = "删除横幅",
    admin_totm_banner_activated = "横幅激活成功！",
    admin_totm_banner_deleted = "横幅删除成功！",
    
    -- Admin Carousel page
    -- ===================
    admin_carousel_title = "轮播图管理",
    admin_carousel_add_button = "添加轮播图",
    admin_carousel_dialog_title = "精选作品集",
    admin_carousel_select_label = "选择要展示的集合：",
    admin_carousel_select_placeholder = "请选择集合",
    admin_carousel_select_required = "请选择一个集合",
    admin_carousel_no_collections = "暂无可用集合",
    admin_carousel_already_exists = "该集合已经在此轮播图中",
    admin_carousel_add_error = "添加失败，请重试",
    
    -- Assignment System (作业系统)
    -- ============================
    
    -- Common
    assignments = "作业",
    assignment = "作业",
    submissions = "提交",
    submission = "提交",
    due_date = "截止日期",
    no_due_date = "无截止日期",
    max_points = "满分",
    points = "得分",
    grade = "等级",
    feedback = "反馈",
    status = "状态",
    version = "版本",
    allow_late = "允许迟交",
    
    -- Status
    status_draft = "草稿",
    status_published = "已发布",
    status_submitted = "已提交",
    status_grading = "批改中",
    status_graded = "已评分",
    is_late = "迟交",
    on_time = "按时",
    
    -- Teacher Pages
    teacher_assignments = "我的作业",
    create_assignment = "创建作业",
    edit_assignment = "编辑作业",
    assignment_title = "作业标题",
    assignment_description = "作业描述",
    template_project = "模板项目",
    select_collection = "选择班级",
    publish_assignment = "发布作业",
    unpublish_assignment = "取消发布",
    delete_assignment = "删除作业",
    view_submissions = "查看提交",
    grade_submissions = "批改作业",
    assignment_stats = "作业统计",
    total_submissions = "提交数",
    graded_count = "已批改",
    average_points = "平均分",
    late_submissions = "迟交数",
    no_assignments = "还没有创建任何作业",
    create_first_assignment = "创建第一个作业",
    
    -- Student Pages  
    student_assignments = "我的作业",
    available_assignments = "可用作业",
    my_submissions = "我的提交",
    submit_assignment = "提交作业",
    resubmit = "重新提交",
    select_project = "选择项目",
    student_note = "备注说明",
    submission_time = "提交时间",
    my_grade = "我的成绩",
    teacher_feedback = "教师反馈",
    no_available_assignments = "暂无可用作业",
    not_submitted = "未提交",
    waiting_for_grade = "等待批改",
    
    -- Assignment Details
    assignment_details = "作业详情",
    created_by = "创建者",
    for_collection = "班级",
    created_at = "创建时间",
    due_at = "截止时间",
    updated_at = "更新时间",
    published_at = "发布时间",
    overdue = "已过期",
    days_left = "@1 天剩余",
    hours_left = "@1 小时剩余",
    
    -- Grading
    grade_submission = "批改提交",
    enter_points = "输入分数",
    enter_grade = "输入等级",
    enter_feedback = "输入反馈",
    save_grade = "保存评分",
    graded_by = "批改人",
    graded_time = "批改时间",
    
    -- Dialogs
    confirm_delete_assignment = "确认删除此作业？@1所有相关的提交记录也将被删除。",
    confirm_publish_assignment = "确认发布此作业？@1发布后学生将可以看到并提交。",
    confirm_unpublish_assignment = "确认取消发布？@1学生将无法继续提交此作业。",
    confirm_submit_assignment = "确认提交此作业？",
    confirm_resubmit_assignment = "确认重新提交？@1这将创建一个新版本。",
    
    -- Success/Error Messages
    assignment_created = "作业创建成功！",
    assignment_updated = "作业更新成功！",
    assignment_deleted = "作业已删除",
    assignment_published = "作业已发布",
    assignment_unpublished = "作业已取消发布",
    submission_success = "提交成功！",
    grade_saved = "评分已保存",
    error_create_assignment = "创建作业失败",
    error_update_assignment = "更新作业失败",
    error_submit_assignment = "提交失败",
    error_grade_submission = "保存评分失败",
    error_no_project_selected = "请选择一个项目",
    error_points_invalid = "分数必须在 0-@1 之间",
    
    -- Teacher Navigation
    teacher_title = "教师页面",
    bulk_tile = "批量创建用户",
    learners_title = "学生管理",
    assignments_title = "作业管理",
    classes_title = "班级管理",
    
    -- Class Management (班级管理)
    -- ============================
    
    -- Common
    classes = "班级",
    class = "班级",
    class_name = "班级名称",
    class_description = "班级描述",
    class_members = "班级成员",
    teacher_classes = "我的班级",
    create_class = "创建班级",
    edit_class = "编辑班级",
    delete_class = "删除班级",
    class_details = "班级详情",
    no_classes = "还没有创建任何班级",
    create_first_class = "创建第一个班级",
    manage_your_classes = "管理您的所有班级",
    no_description = "暂无描述",
    
    -- Students in Class
    add_student = "添加学生",
    remove_student = "移除学生",
    student_username = "学生用户名",
    student_email = "学生邮箱",
    joined_at = "加入时间",
    submitted_assignments = "已提交作业数",
    class_student_note = "学生备注",
    class_student_note_placeholder = "如：学号、座位号等",
    no_students_in_class = "班级中还没有学生",
    select_student = "选择学生",
    please_select_student = "请选择一个学生",
    
    -- Status
    active = "激活",
    inactive = "停用",
    activate = "激活",
    deactivate = "停用",
    
    -- Actions
    view_details = "查看详情",
    add = "添加",
    remove = "移除",
    save = "保存",
    create = "创建",
    optional = "可选",
    
    -- Messages
    class_created = "班级创建成功！",
    class_updated = "班级更新成功！",
    class_deleted = "班级已删除",
    student_added = "学生添加成功！",
    student_removed = "学生已移除",
    status_updated = "状态更新成功",
    class_name_required = "班级名称不能为空",
    
    -- Errors
    error_create_class = "创建班级失败",
    error_update_class = "更新班级失败",
    error_delete_class = "删除班级失败",
    error_add_student = "添加学生失败",
    error_remove_student = "移除学生失败",
    error_update_status = "更新状态失败",
    
    -- Confirmations
    confirm_delete_class = "确认删除班级 @1？",
    confirm_remove_student = "确认从班级中移除学生 @1？",
    
    -- Bulk creation
    bulk_text = "上传 CSV 文件或粘贴 CSV 内容以批量创建学生账号。格式：用户名,密码",
    bulk_make_collection = "创建班级合集",
    bulk_create = "创建学生账号",
    
    -- User Info Enhancements (新增字段)
    -- ======================
    real_name = "真实姓名",
    submitted = "已提交",
    average_score = "平均分数",
    completion_rate = "完成率",
    creator = "创建者",
    unverified = "未验证",
    more_items = "还有 @1 项",
    total_projects = "总项目数",
    view_user_projects = "查看用户的项目",
    view_user_page = "进入用户页面",
    all_projects = "所有项目",
    
    -- User Actions (新增字段)
    confirm_action = "确认操作",
    confirm_reset_password = "确认重置用户 @1 的密码？",
    confirm_revive = "确认恢复用户 @1？",
    confirm_perma_delete = "确认永久删除用户 @1？",
    delete_user = "确认删除用户 @1？",
    revive_usr = "恢复用户",
    perma_delete_usr = "永久删除",
    delete_date = "删除日期",
}

return locale
