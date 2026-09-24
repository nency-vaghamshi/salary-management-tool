# Small design-system primitives shared by every page. Class strings are
# written out in full (never built by interpolation) so Tailwind's scanner
# always sees them.
module UiHelper
  BUTTON_CLASSES = {
    primary: "bg-indigo-600 text-white shadow-xs hover:bg-indigo-700",
    secondary: "bg-white text-gray-700 ring-1 ring-inset ring-gray-300 shadow-xs hover:bg-gray-50",
    ghost: "text-gray-600 hover:bg-gray-100 hover:text-gray-900",
    danger: "bg-white text-red-600 ring-1 ring-inset ring-red-200 shadow-xs hover:bg-red-50"
  }.freeze
  BUTTON_BASE = "inline-flex items-center justify-center gap-1.5 rounded-md px-3 py-2 text-sm font-medium " \
                "transition-colors cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed".freeze

  # Status -> [tone classes, dot class]. One map for every model's status
  # enum, so "active" looks the same on an employment and a salary record.
  STATUS_TONES = {
    "active" => %w[bg-green-50 text-green-700 ring-green-600/20 bg-green-500],
    "completed" => %w[bg-green-50 text-green-700 ring-green-600/20 bg-green-500],
    "processing" => %w[bg-blue-50 text-blue-700 ring-blue-600/20 bg-blue-500],
    "draft" => %w[bg-amber-50 text-amber-800 ring-amber-600/20 bg-amber-500],
    "failed" => %w[bg-red-50 text-red-700 ring-red-600/20 bg-red-500],
    "terminated" => %w[bg-red-50 text-red-700 ring-red-600/20 bg-red-500],
    "inactive" => %w[bg-gray-50 text-gray-600 ring-gray-500/20 bg-gray-400]
  }.freeze

  INPUT_CLASS = "block w-full rounded-md border-0 bg-white px-3 py-2 text-sm text-gray-900 shadow-xs " \
                "ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 " \
                "focus:ring-2 focus:ring-inset focus:ring-indigo-600 focus:outline-none".freeze

  def ui_button_class(variant = :primary)
    "#{BUTTON_BASE} #{BUTTON_CLASSES.fetch(variant)}"
  end

  def ui_input_class
    INPUT_CLASS
  end

  def status_badge(status, label: nil)
    tone, text, ring, dot = STATUS_TONES.fetch(status.to_s, STATUS_TONES["inactive"])
    tag.span(class: "inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset #{tone} #{text} #{ring}") do
      safe_join([ tag.span(class: "size-1.5 rounded-full #{dot}", aria: { hidden: true }), label || status.to_s.titleize ])
    end
  end

  # Currencies imported with the ISO code as their symbol ("EUR") read better
  # as "EUR 1,234.00" than "EUR1,234.00"; real symbols stay tight ("€1,234").
  def format_money(amount, currency, precision: 2)
    return "—" if amount.nil?

    symbol = currency.symbol.presence || currency.code
    format = symbol.match?(/\A[A-Za-z]{2,}\z/) ? "%u %n" : "%u%n"
    number_to_currency(amount, unit: symbol, precision: precision, format: format, negative_format: "-#{format}")
  end

  def page_header(title:, description: nil, breadcrumbs: [], &actions)
    render "shared/page_header", title: title, description: description,
                                 breadcrumbs: breadcrumbs, actions: (capture(&actions) if actions)
  end

  ROLE_LABELS = { "hr_manager" => "HR Manager" }.freeze

  def role_label(role)
    ROLE_LABELS.fetch(role.to_s) { role.to_s.titleize }
  end

  def initials_for(name)
    name.to_s.split.first(2).map { |part| part[0] }.join.upcase
  end
end
