require 'active_record'
require 'helper'
require 'tush'

describe Tush::AssociationHelpers do

  before :all do

    class Jacob < ActiveRecord::Base
      belongs_to :jesse
    end

    class Jesse < ActiveRecord::Base
      has_one :jim
      has_one :picture, :as => :imageable
    end

    class Jim < ActiveRecord::Base
      belongs_to :jesse
      has_many :leah
    end

    class Leah < ActiveRecord::Base
      belongs_to :jim
    end

    class Picture < ActiveRecord::Base
      belongs_to :imageable, :polymorphic => true
    end
  end

  describe ".relation_infos" do

    it "returns an info for an association" do
      infos = Tush::AssociationHelpers.relation_infos(:has_one, Jesse)

      infos.count.should == 2
      infos.first.name.should == :jim
      infos.last.name.should == :picture
    end

    it "works with string classes" do
      infos = Tush::AssociationHelpers.relation_infos(:belongs_to, "Jacob")

      infos.count.should == 1
      infos.first.name.should == :jesse
    end

  end

  describe ".model_relation_info" do

    it "returns a mapping of association to relation info" do
      info = Tush::AssociationHelpers.model_relation_info(Jim)

      info.keys.should == Tush::SUPPORTED_ASSOCIATIONS
      info[:has_many].count.should == 1
      info[:has_many].first.name.should == :leah
    end

  end

  describe ".create_foreign_key_mapping" do
    let!(:jesse) { Jesse.create }
    let!(:jacob) { Jacob.create(:jesse_id => jesse.id) }
    let!(:jim)   { Jim.create(:jesse_id => jesse.id) }
    let!(:leah)  { Leah.create(:jim_id => jim.id) }
    let!(:jesse_pic) { Picture.create(:imageable_id => jesse.id, :imageable_type => 'Jesse')}

    let!(:jesse_wrapper) { Tush::ModelWrapper.new(:model => jesse) }
    let!(:jacob_wrapper) { Tush::ModelWrapper.new(:model => jacob) }
    let!(:jim_wrapper)   { Tush::ModelWrapper.new(:model => jim) }
    let!(:leah_wrapper)  { Tush::ModelWrapper.new(:model => leah) }
    let!(:jesse_pic_wrapper) { Tush::ModelWrapper.new(:model => jesse_pic) }

    it "it finds the appropriate foreign keys for the passed in classes" do
      mapping = Tush::AssociationHelpers.create_foreign_key_mapping([jacob_wrapper, jesse_wrapper, jim_wrapper, leah_wrapper, jesse_pic_wrapper])

      mapping.should == { Jacob => [{ :foreign_key=>"jesse_id", :class=> Jesse }],
                          Jesse => [],
                          Jim => [{ :foreign_key=>"jesse_id", :class=> Jesse }],
                          Leah => [{ :foreign_key=>"jim_id", :class=> Jim }],
                          Picture => [{ :foreign_key=>"imageable_id", :class=> Jesse }] }
    end

    it "it returns newly discovered classes in the mapping if an input class has \
        a has_many or a has_one" do
      mapping = Tush::AssociationHelpers.create_foreign_key_mapping([jacob_wrapper, jesse_wrapper])

      mapping.should == { Jacob => [{ :foreign_key=>"jesse_id", :class=> Jesse }],
                          Jesse => [],
                          Jim => [{ :foreign_key=>"jesse_id", :class=> Jesse }],
                          Picture => [{ :foreign_key=>"imageable_id", :class=>Jesse }] }
    end


  end

end
