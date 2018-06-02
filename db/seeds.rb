User.create!(name:  "arakawa",
             email: "hoge@hoge.com",
             password:              "11111111",
             password_confirmation: "11111111",
             admin: true)

99.times do |n|
  name  = Faker::Name.name
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  User.create!(name:  name,
               email: email,
               password:              password,
               password_confirmation: password)
end
