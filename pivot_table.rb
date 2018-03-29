# ActiveRecordのSELECT結果からピボットテーブル（集計表）を作るためのユーティリティクラス
class PivotTable
  def initialize(rows, x_key:, y_key:, x_values:)
    @rows = rows
    @x_key = x_key
    @y_key = y_key
    @x_values = x_values
    @y_values = @rows.map {|row| row[@y_key]}.uniq
  end

  def to_hash
    hash = Hash.new {|h, k| h[k] = {}}

    @rows.each do |row|
      hash[row[@y_key]][row[@x_key]] = row
    end

    return hash
  end

  def to_array2d
    ret = []
    hash = to_hash

    ret << [""] + @x_values

    @y_values.each do |yv|
      a = [yv]
      @x_values.each do |xv|
        a << hash[yv][xv]
      end
      ret << a
    end

    return ret
  end
end


# 使用例
if $0 == __FILE__
  include ApplicationHelper

  conn = ActiveRecord::Base.connection
  sql = <<-EOS
    SELECT
      api_key,
      dt,
      sum(success) AS success,
      sum(failure) AS failure
    FROM
      counters
    WHERE
      dt >= '2018-03-01' AND
      dt < '2018-04-01'
    GROUP BY
      api_key,
      dt
    ORDER BY
      api_key,
      dt
  EOS

  rows = ActiveRecord::Base.connection.select_all(sql)

  x_values = (1..31).map {|x| "2018-03" + sprintf("-%02d", x)}
  #y_values = rows.map {|x| x["api_key"]}.uniq

  pivot_table = PivotTable.new(
    rows,
    x_key: "dt",
    y_key: "api_key",
    x_values: x_values
  )

  pivot_table.to_array2d.each do |row|
    p row.map {|cell|
      if cell.nil?
        ""
      elsif cell.is_a?(Hash)
        cell["success"].to_i
      else
        cell
      end
    }
  end
end
