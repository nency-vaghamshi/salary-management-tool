# Turns monthly payroll totals into chart geometry for the dashboard's
# "Payroll Cost Over Time" line chart. Kept out of the view so the template
# only places marks, and out of the controller since it is pure presentation.
#
# Coordinates are percentages of the plot area: the SVG only draws lines
# (stretched with non-scaling strokes), while dots, labels and tooltips are
# HTML positioned by %, so text stays legible at any screen width.
#
# The x-axis is a fixed run of calendar months, so spacing reflects real time;
# a month with no completed run is a gap in the line, never a fake zero.
class PayrollCostChart
  TICK_COUNT = 4

  Point = Struct.new(:month, :x, :y, :payroll, keyword_init: true) do
    def present?
      !payroll.nil?
    end
  end

  attr_reader :points

  # monthly_payrolls: rows responding to #month (Date, 1st of month) and
  # #gross_total; months: the calendar months to plot, oldest first.
  def initialize(monthly_payrolls, months:)
    by_month = monthly_payrolls.index_by(&:month)
    @max_value = nice_ceiling(monthly_payrolls.map(&:gross_total).max.to_f)
    @points = months.each_with_index.map do |month, index|
      payroll = by_month[month]
      Point.new(month: month, x: (index + 0.5) / months.size * 100, y: payroll && y_for(payroll.gross_total), payroll: payroll)
    end
  end

  def any_data?
    points.any?(&:present?)
  end

  # Consecutive months with data become one polyline; a missing month breaks it.
  def line_segments
    points.chunk_while { |a, b| a.present? && b.present? }
          .select { |run| run.first.present? && run.size > 1 }
          .map { |run| run.map { |point| "#{point.x.round(3)},#{point.y.round(3)}" }.join(" ") }
  end

  def y_ticks
    step = @max_value / TICK_COUNT
    (0..TICK_COUNT).map { |i| { value: step * i, y: y_for(step * i) } }
  end

  def latest_point
    points.reverse.find(&:present?)
  end

  private

  def y_for(value)
    return 100.0 if @max_value.zero?

    100 - (value.to_f / @max_value * 100)
  end

  # Rounds the axis top up to a clean 1/2/2.5/5 x 10^n step per tick, so tick
  # labels read as round numbers (0, 50M, 100M ...) instead of 42.8M.
  def nice_ceiling(max)
    return 0.0 if max <= 0

    raw_step = max / TICK_COUNT
    magnitude = 10**Math.log10(raw_step).floor
    nice_step = [ 1, 2, 2.5, 5, 10 ].map { |factor| factor * magnitude }.find { |candidate| candidate >= raw_step }
    nice_step * TICK_COUNT
  end
end
