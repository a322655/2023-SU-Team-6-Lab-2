class SectionsCourseColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column(:sections, :course)
  end
end
