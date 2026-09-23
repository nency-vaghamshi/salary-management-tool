class RemoveLegalEntityAndWorkLocationFromEmployments < ActiveRecord::Migration[8.0]
  def change
    remove_reference :employments, :legal_entity, foreign_key: true
    remove_reference :employments, :work_location, foreign_key: true
  end
end
