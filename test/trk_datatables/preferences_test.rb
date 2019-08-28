require 'test_helper'

class Preferences < Minitest::Test
  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'posts.published_date': {},
        'users.email': {},
      }
    end

    def rows(_filtered); end

    def preferences_holder
      @view.current_user
    end
  end

  # rubocop:disable Rails/TimeZone
  def test_set_preference_on_order
    user = User.create
    post1 = Post.create published_date: Time.parse('2020-01-01'), title: 'b'
    post2 = Post.create published_date: Time.parse('2020-03-01'), title: 'a'
    post3 = Post.create published_date: Time.parse('2020-02-01'), title: 'c'
    assert_nil user.preferences[:dt_preferences]

    datatable = PostsDatatable.new OpenStruct.new params: {}, current_user: user
    results = datatable.order_and_paginate_items datatable.all_items
    assert_equal [post3, post1, post2], results.all, 'cba expected by ' + results.all.to_sql

    datatable = PostsDatatable.new OpenStruct.new params: { order: { '0': { column: '1', dir: 'desc' } } }, current_user: user
    results = datatable.order_and_paginate_items datatable.all_items
    refute_nil user.preferences[:dt_preferences]
    assert_equal [post2, post3, post1], results.all

    # use saved params
    datatable = PostsDatatable.new OpenStruct.new params: {}, current_user: user
    results = datatable.order_and_paginate_items datatable.all_items
    assert_equal [post2, post3, post1], results.all

    # revert to default if there is no user
    datatable = PostsDatatable.new OpenStruct.new params: {}, current_user: nil
    results = datatable.order_and_paginate_items datatable.all_items
    assert_equal [post3, post1, post2], results.all, 'cba expected by ' + results.all.to_sql

    # order with two columns
    datatable = PostsDatatable.new OpenStruct.new params: { order: { '0': { column: '2', dir: 'desc' }, '1': { column: '1', dir: :asc } } }, current_user: user
    results = datatable.order_and_paginate_items datatable.all_items
    assert_equal [post1, post3, post2], results.all
  end
  # rubocop:enable Rails/TimeZone

  def test_preferences_on_page_length
    user = User.create
    post1 = Post.create title: 'a'
    post2 = Post.create title: 'b'
    post3 = Post.create title: 'c'
    assert_nil user.preferences[:dt_preferences]

    datatable = PostsDatatable.new OpenStruct.new params: {}, current_user: user
    results = datatable.order_and_paginate_items datatable.all_items
    assert_equal [post3, post2, post1], results.all

    datatable = PostsDatatable.new OpenStruct.new params: { length: '1' }, current_user: user
    results = datatable.order_and_paginate_items datatable.all_items
    assert_equal [post3], results.all

    datatable = PostsDatatable.new OpenStruct.new params: {}, current_user: user
    results = datatable.order_and_paginate_items datatable.all_items
    assert_equal [post3], results.all
  end
end