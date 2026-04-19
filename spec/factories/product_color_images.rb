FactoryBot.define do
  factory :product_color_image do
    association :product_color
    angle { :front }

    ProductColorImage.angles.each_key do |a|
      trait a.to_sym do
        angle { a }
      end
    end
  end
end
