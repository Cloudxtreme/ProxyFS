
require File.dirname(__FILE__) + "/../../config/database"

class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string :command
      t.string :path
      t.string :file
      t.references :mirror

      t.timestamps
    end

    add_index :tasks, :mirror_id
  end

  def self.down
    drop_table :tasks
  end
end

