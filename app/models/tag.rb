class Tag < ActiveRecord::Base
  has_many :taggings,
    :dependent => :delete_all
  has_many :stories,
    :through => :taggings

  attr_accessor :filtered_count, :stories_count

  scope :accessible_to, ->(user) do
    user && user.is_moderator?? all : where(:privileged => false)
  end

  scope :active, -> { where(:inactive => false) }
  scope :tier, ->(i) { where(tier: i)}

  def to_param
    self.tag
  end

  def self.all_with_filtered_counts_for(user)
    counts = TagFilter.group(:tag_id).count

    Tag.active.order('tier, tag').accessible_to(user).map{|t|
      t.filtered_count = counts[t.id].to_i
      t
    }
  end

  def self.all_with_story_counts_for(user)
    counts = Tagging.group(:tag_id).count

    Tag.active.order('tier, tag').accessible_to(user).map{|t|
      t.stories_count = counts[t.id].to_i
      t
    }
  end

  def css_class
    "tag tag_#{self.tag} tag-tier-#{self.tier}" << (self.is_media?? " tag_is_media" : "")
  end

  def valid_for?(user)
    if self.privileged?
      user.is_moderator?
    else
      true
    end
  end

  def story_count_in(other_tags)
    Tagging.where(tag_id: other_tags + [self]).group(:story_id).having('count(story_id) = ?', other_tags.count + 1).count.count
  end

  def filtered_count
    @filtered_count ||= TagFilter.where(:tag_id => self.id).count
  end
end
