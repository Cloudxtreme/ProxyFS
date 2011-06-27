
require File.dirname(__FILE__) + "/../../config/database"

class CreateMirrors < ActiveRecord::Migration
  def self.up
    create_table :mirrors do |t|
      t.string :hostname
      t.string :username
      t.string :base_path

      t.timestamps
    end
  end

  def self.down
    drop_table :mirrors
  end
end

