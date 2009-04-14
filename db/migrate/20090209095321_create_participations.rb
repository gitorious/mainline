class CreateParticipations < ActiveRecord::Migration
  def self.up
    # create_table :participations do |t|
    #   t.integer   :group_id, :null => false
    #   t.integer   :repository_id, :null => false
    #   t.integer   :creator_id
    #   t.timestamps
    # end
    # add_index :participations, [:group_id, :repository_id]
  end

  def self.down
    # drop_table :participations
  end
end
