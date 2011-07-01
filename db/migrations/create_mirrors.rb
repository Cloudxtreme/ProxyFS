
require File.dirname(__FILE__) + "/../../config/database"

class CreateMirrors < ActiveRecord::Migration
  def self.up
    create_table :mirrors do |t|
      t.string :hostname, :unique => true
      t.string :username
      t.string :base_path

      t.timestamps
    end

    add_index :mirrors, :hostname
  end

  def self.down
    drop_table :mirrors
  end
end

